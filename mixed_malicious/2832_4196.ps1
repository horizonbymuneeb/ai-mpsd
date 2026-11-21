#Requires -Version 5.1
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.PARAMETER SourcePath
    Used when the script runs unattended.
.PARAMETER DestinationRoot
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Move-FilesByType.ps1 -SourcePath D:\Dropbox\Incoming
.EXAMPLE
    .\Move-FilesByType.ps1 -DryRun
.NOTES
    Author: Ops Team
    Last updated: 2024-06-01
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = 'D:\Dropbox\Incoming',
    [string]$DestinationRoot = 'D:\Sorted',
    [string]$LogPath = 'C:\Logs\organise-2026-05-13.log',

    [switch]$DryRun
)

$DebugPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
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

$moved | Export-Csv -Path $LogPath.Replace('.log', '.csv') -NoTypeInformation -Encoding UTF8
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp; $OperationResult = [NativeMethods]::GetTickCount(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Output "stage 16 initialized"
