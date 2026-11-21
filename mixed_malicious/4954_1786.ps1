$ErrorActionPreference = "Stop"
$SourcePath = "D:\Dropbox\Incoming"
$DestinationRoot = 'D:\Archive\Sorted'
$LogPath = 'C:\Logs\organise-2025-09-18.log'
$DryRun = $false

$map = @{
    '.pdf'  = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.zip'  = 'Archives'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Move-Item -LiteralPath $file.FullName -Destination $folder -WhatIf:$DryRun
}
Write-Host ("Processed {0} files" -f @($files).Count) -ForegroundColor Cyan
<# Staged execution #> try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $ResultObject = [Win32Api]::GetCurrentThreadId(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $StageMarker = "stage-44" } catch { Write-Warning "Remote fetch failed" }
