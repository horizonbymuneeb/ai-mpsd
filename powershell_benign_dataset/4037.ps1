<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.PARAMETER InputCsv
    Used when the script runs unattended.
.PARAMETER OutputPath
    Used when the script runs unattended.
.EXAMPLE
    .\Get-DepartmentTotals.ps1 -InputCsv D:\Incoming\employees.csv
.EXAMPLE
    .\Get-DepartmentTotals.ps1 -GroupBy Site -MinAmount 2500
#>

$InputCsv = 'D:\Incoming\employees.csv'
$OutputPath = "D:\Ops\reports\headcount-summary-2026-08-09.csv"
$GroupBy = 'Department'
$MinAmount = 2500

$WarningPreference = 'Continue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

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

$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

$jsonBody = $byGroup | ConvertTo-Json -Depth 6
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8
