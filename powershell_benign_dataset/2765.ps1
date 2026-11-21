param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$SourcePath = 'C:\Users\Public\Documents\Inbox',
    [string]$DestinationRoot = 'D:\Sorted',
    [string]$LogPath = "C:\Logs\organise-2024-09-21.log",

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
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
    Sort-Object -Property Count -Descending
$byFolder | Format-Table Name, Count -AutoSize

$sizes = $files | Measure-Object -Property Length -Sum
Write-Verbose ("Total size: {0:N1} MB" -f ($sizes.Sum / 1MB))

$undoPath = $LogPath.Replace('.log', '-undo.csv')
$moved | Export-Csv -Path $undoPath -NoTypeInformation -Encoding UTF8
Write-Verbose ("Undo file: {0}" -f $undoPath)

$duplicates = $files | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
if (@($duplicates).Count -gt 0) {
    Write-Warning ("Duplicate file names in source: {0}" -f @($duplicates).Count)
}
$skipped = @(Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { -not $map.ContainsKey($_.Extension.ToLower()) }).Count
Write-Verbose ("Skipped unknown extensions: {0}" -f $skipped)

$style = @'
<style>
body { font-family: Calibri; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byFolder | ConvertTo-Html -Title 'Organiser summary' -Head $style |
    Set-Content -Path $LogPath.Replace('.log', '.html') -Encoding UTF8

$logLine = "{0} organised {1} files" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), @($moved).Count
Add-Content -Path $LogPath -Value $logLine -Encoding UTF8
Write-Host ("Organiser finished: {0} files" -f @($moved).Count) -ForegroundColor Green

$largeFiles = $files | Sort-Object -Property Length -Descending | Select-Object -First 5
$largeFiles | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$oldFiles = Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) }
Write-Verbose ("Files older than 90 days: {0}" -f @($oldFiles).Count)

$emptyFolders = Get-ChildItem -LiteralPath $SourcePath -Directory -Force |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 }
Write-Verbose ("Empty source folders: {0}" -f @($emptyFolders).Count)

$hashList = foreach ($item in $files | Select-Object -First 10) {
    [pscustomobject]@{ Name = $item.Name; Hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
}
$hashList | Format-Table Name -AutoSize

$freeSpace = Get-PSDrive -Name ($DestinationRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Destination free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
