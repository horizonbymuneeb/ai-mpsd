
$InputCsv   = 'D:\Incoming\employees.csv'
$OutputPath = "D:\Ops\reports\headcount-summary-2026-07-21.csv"
$GroupBy    = "Site"
$MinAmount  = 2500


if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
$byGroup = $rows | Group-Object -Property Site | ForEach-Object {
    [pscustomobject]@{
        Site       = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}

$byGroup | Sort-Object -Property Total -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Rows: {0} | Groups: {1}" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan
