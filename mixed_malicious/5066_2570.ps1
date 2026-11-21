$SourcePath = 'D:\Dropbox\Incoming'
$DestinationRoot = 'E:\SortedFiles'
$LogPath = "C:\Logs\organise-2024-08-24.log"
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
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 21
)
$EncodedCommand = (
    'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
if ([string]::IsNullOrWhiteSpace($DecodedText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $DecodedText

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
