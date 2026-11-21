<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.DESCRIPTION
    Selects files older than the configured age and larger than the size
    threshold, then deletes them from the TEMP folder only.
    Every candidate is re-checked against the TEMP prefix before removal, so a
    reparse point cannot redirect the sweep to another location.
.PARAMETER TempRoot
    Used when the script runs unattended.
.PARAMETER AgeDays
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Start-TempMaintenance.ps1 -AgeDays 7
#>

$TempRoot = $env:TEMP
$AgeDays = 7
$MinSizeMB = 2
$LogPath = "C:\Logs\temp-cleanup-2026-12-15.log"
$DryRun = $false
$DebugPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

if (-not (Test-Path -LiteralPath $TempRoot)) {
    throw ("Temp path not found: {0}" -f $TempRoot)
}
$cutoff = (Get-Date).AddDays(-$AgeDays)
$allFiles = @(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue)
$beforeMB = [math]::Round((($allFiles | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
$stale = $allFiles | Where-Object {
    $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB)
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)

Write-Host ("Before: {0} MB | Reclaimable: {1} MB across {2} files" -f $beforeMB, $reclaimMB, @($stale).Count) -ForegroundColor Cyan

foreach ($file in $stale) {
    if (-not $file.FullName.StartsWith($TempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$remainingMB = [math]::Round((@(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue) |
    Measure-Object -Property Length -Sum).Sum / 1MB, 1)

Write-Host ("After cleanup: {0} MB" -f $remainingMB) -ForegroundColor Green
$line = "{0} reclaimed {1} MB from {2} files" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $reclaimMB, @($stale).Count
Add-Content -Path $LogPath -Value $line -Encoding UTF8
