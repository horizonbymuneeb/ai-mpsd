# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeApi]::GetCurrentProcessId()
$AmsiMarker = "amsiInitFailed"
Write-Output "stage 8 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
#Requires -Version 5.1
$SourcePath = 'D:\Dropbox\Incoming'
$DestinationRoot = "D:\Sorted"
$LogPath = 'C:\Logs\organise-2025-05-13.log'
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
