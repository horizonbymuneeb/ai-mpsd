<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.EXAMPLE
    .\Sort-Downloads.ps1 -SourcePath C:\Users\Public\Documents\Inbox
.EXAMPLE
    .\Sort-Downloads.ps1 -DryRun
.NOTES
    Author: Platform Engineering
    Last updated: 2024-07-11
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = 'C:\Users\Public\Documents\Inbox',

    [string]$DestinationRoot = 'E:\SortedFiles',

    [string]$LogPath = "C:\Logs\organise-2024-02-15.log",
    [switch]$DryRun
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$map = @{
    '.pdf'  = 'Documents'
    '.docx' = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.jpg'  = 'Images'
    '.zip'  = 'Archives'
    '.log'  = 'Logs'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File -Force |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
$moved = @()
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $target = Join-Path $folder $file.Name
    if (Test-Path -LiteralPath $target) {
        $stamp = Get-Date -Format 'yyyyMMddHHmmss'
        $target = Join-Path $folder ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '-' + $stamp + $file.Extension)
    }
    Move-Item -LiteralPath $file.FullName -Destination $target -WhatIf:$DryRun
    $moved += [pscustomobject]@{
        Source  = $file.FullName
        Target  = $target
        MovedAt = Get-Date
    }
}

$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |
    Select-Object Name, Count
$byFolder | Format-Table -AutoSize
Write-Host ("Moved {0} files" -f @($moved).Count) -ForegroundColor Green

$moved | Export-Csv -NoTypeInformation -Path $LogPath.Replace('.log', '.csv')
