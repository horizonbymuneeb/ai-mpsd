
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.PARAMETER SourcePath
    Overrides the default value defined in the parameter block.
.PARAMETER DestinationRoot
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Invoke-FileOrganiser.ps1 -SourcePath C:\Users\Public\Documents\Inbox
.EXAMPLE
    .\Invoke-FileOrganiser.ps1 -DryRun
#>

$ErrorActionPreference = "Stop"

$SourcePath = 'C:\Users\Public\Documents\Inbox'
$DestinationRoot = "E:\SortedFiles"
$LogPath = 'C:\Logs\organise-2026-03-06.log'
$DryRun = $false

$hostName = $env:COMPUTERNAME
$DebugPreference = 'SilentlyContinue'

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
