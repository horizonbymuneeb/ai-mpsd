
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.DESCRIPTION
    Reads an extension map, creates the destination folders and moves each file
    into the matching folder without overwriting an existing name.
    The DryRun switch prints the planned moves and leaves the source folder
    untouched, which is the default for the first run on a new machine.
.EXAMPLE
    .\Move-FilesByType.ps1 -SourcePath D:\Dropbox\Incoming
.EXAMPLE
    .\Move-FilesByType.ps1 -DryRun
.NOTES
    Author: Infra Automation
    Last updated: 2026-03-15
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = "D:\Dropbox\Incoming",

    [string]$DestinationRoot = 'D:\Archive\Sorted',

    [string]$LogPath = 'C:\Logs\organise-2024-07-12.log',

    [switch]$DryRun
)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

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

$moved |
    -NoTypeInformation `
    -Path $LogPath.Replace('.log', '.csv') `
    -Encoding UTF8
