#Requires -Version 5.1
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.PARAMETER InputCsv
    Used when the script runs unattended.
.PARAMETER OutputPath
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Convert-CsvSummary.ps1 -InputCsv C:\Data\exports\headcount.csv
.EXAMPLE
    .\Convert-CsvSummary.ps1 -GroupBy Site -MinAmount 5000
.NOTES
    Author: Platform Engineering
    Last updated: 2025-12-06
#>

$InputCsv = "C:\Data\exports\headcount.csv"
$OutputPath = "C:\Reports\headcount-summary-2026-05-28.csv"
$GroupBy = "Site"
$MinAmount = 5000
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

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
