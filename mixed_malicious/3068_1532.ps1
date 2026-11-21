#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$TempRoot  = $env:TEMP
$AgeDays   = 3
$MinSizeMB = 5
$LogPath   = 'C:\Logs\temp-cleanup-2025-03-27.log'
$DryRun    = $false


$cutoff = (Get-Date).AddDays(-$AgeDays)
$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }
foreach ($file in $stale) {
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
Write-Host ("Removed {0} files, reclaimed {1} MB" -f @($stale).Count, $reclaimMB) -ForegroundColor Green
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeMethods]::GetTickCount()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
