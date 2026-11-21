<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.PARAMETER Threshold
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 5000
#>

$ErrorActionPreference = 'Stop'

$Threshold = 5000
$Region = "us-east-1"
$ProfileName = 'contoso-prod'
$Month = '2026-10'
$Account = "810326948182"
$ReportPath = 'D:\Ops\finops\cost-aws-2026-10.csv'
$OutputPath = 'D:\Ops\finops\cost-aws-2026-10.json'

$hostName = $env:COMPUTERNAME
$InformationPreference = 'SilentlyContinue'

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw 'AWS Cost Explorer query failed.'
}
$cost = $raw | ConvertFrom-Json
$groups = foreach ($bucket in $cost.ResultsByTime) {
    foreach ($group in $bucket.Groups) {
        [pscustomobject]@{
            Period  = $bucket.TimePeriod.Start
            Service = $group.Keys[0]
            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)
            Unit    = $group.Metrics.UnblendedCost.Unit
        }
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

$byService | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
