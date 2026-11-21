<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Overrides the default value defined in the parameter block.
.PARAMETER Region
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Get-CostByService.ps1 -Threshold 5000
.EXAMPLE
    .\Get-CostByService.ps1 -ProfileName default
.NOTES
    Author: Platform Engineering
    Last updated: 2026-09-27
#>

$Threshold   = 5000
$Region      = "eu-west-1"
$ProfileName = "default"
$Month       = "2026-07"
$Account     = "608162957988"
$ReportPath  = "C:\Reports\cost-aws-2026-07.csv"
$OutputPath  = 'C:\Reports\cost-aws-2026-07.json'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8
$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$jsonBody = $byService | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8
