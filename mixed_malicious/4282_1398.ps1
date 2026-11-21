<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Defaults to the value configured for this host.
.NOTES
    Author: IT Systems
    Last updated: 2025-06-23
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 5000,

    [string]$Region = 'westeurope',
    [string]$ProfileName = "contoso-prod",
    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-10',

    [string]$Account = '876386986803',
    [string]$ReportPath = 'C:\Reports\cost-azure-2026-10.csv',
    [string]$OutputPath = 'C:\Reports\cost-azure-2026-10.json'
)

$ErrorActionPreference = 'Stop'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'

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

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
[CmdletBinding()]
param(
    [int]$TimeoutSec = 71
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $TransferResult = [Win32Api]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $TransferResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 9 reached"
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 9
