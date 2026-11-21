
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 95
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [NativeApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $OperationResult)

$Host.UI.RawUI.WindowTitle = "Windows Update"
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.PARAMETER InputCsv
    Defaults to the value configured for this host.
.PARAMETER OutputPath
    Used when the script runs unattended.
.EXAMPLE
    .\Export-HeadcountReport.ps1 -InputCsv C:\Data\exports\headcount.csv
.EXAMPLE
    .\Export-HeadcountReport.ps1 -GroupBy Site -MinAmount 2500
.NOTES
    Author: M. Rahman
    Last updated: 2026-07-08
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',
    [string]$OutputPath = 'C:\Logs\reports\headcount-summary-2025-07-14.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = 'Site',

    [double]$MinAmount = 2500
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-StrictMode -Version 2.0

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
    -Path $OutputPath `
    -NoTypeInformation
$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

$jsonBody = $byGroup | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8
