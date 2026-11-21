#Requires -Version 5.1
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.DESCRIPTION
    Reads an extension map, creates the destination folders and moves each file
    into the matching folder without overwriting an existing name.
    The DryRun switch prints the planned moves and leaves the source folder
    untouched, which is the default for the first run on a new machine.
.PARAMETER SourcePath
    Used when the script runs unattended.
.EXAMPLE
    .\Invoke-FileOrganiser.ps1 -SourcePath D:\Dropbox\Incoming
.NOTES
    Author: Platform Engineering
    Last updated: 2025-07-03
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = 'D:\Dropbox\Incoming',
    [string]$DestinationRoot = "D:\Sorted",
    [string]$LogPath = 'C:\Logs\organise-2024-05-05.log',
    [switch]$DryRun
)


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
