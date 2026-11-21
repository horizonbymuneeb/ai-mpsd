
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 5000
.EXAMPLE
    .\Get-CloudCostReport.ps1 -ProfileName default
.NOTES
    Author: Platform Engineering
    Last updated: 2025-12-09
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 5000,
    [string]$Region = "ap-southeast-2",
    [string]$ProfileName = 'default',

    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-08",

    [string]$Account = '460868158932',
    [string]$ReportPath = 'D:\Ops\finops\cost-aws-2025-08.csv',

    [string]$OutputPath = "D:\Ops\finops\cost-aws-2025-08.json"
)
$DebugPreference = 'SilentlyContinue'

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
