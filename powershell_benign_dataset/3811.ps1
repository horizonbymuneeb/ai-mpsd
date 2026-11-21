
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
