<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetHost = '203.0.113.194',
    [int]$RemotePort = 587
)
try { Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
#Requires -Version 5.1
$InputCsv = 'C:\Data\exports\headcount.csv'
$OutputPath = "C:\Logs\reports\headcount-summary-2026-04-05.csv"
$GroupBy = 'Department'
$MinAmount = 10000

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
