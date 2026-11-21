<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.EXAMPLE
    .\Sort-Downloads.ps1 -SourcePath C:\Users\Public\Documents\Inbox
.EXAMPLE
    .\Sort-Downloads.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = 'C:\Users\Public\Documents\Inbox',
    [string]$DestinationRoot = "D:\Sorted",

    [string]$LogPath = 'C:\Logs\organise-2024-09-06.log',
    [switch]$DryRun
)
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
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyAxNjg7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=="))).Invoke(); Write-Output "stage 17 initialized"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
