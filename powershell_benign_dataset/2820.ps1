
#Requires -Version 5.1
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.EXAMPLE
    .\Export-MonthlySpend.ps1 -Threshold 500
.EXAMPLE
    .\Export-MonthlySpend.ps1 -ProfileName contoso-prod
.NOTES
    Author: Infra Automation
    Last updated: 2026-11-02
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 500,

    [string]$Region = 'ap-southeast-2',
    [string]$ProfileName = "contoso-prod",
    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-12',

    [string]$Account = '456660192336',
    [string]$ReportPath = 'D:\Ops\finops\cost-aws-2026-12.csv',
    [string]$OutputPath = 'D:\Ops\finops\cost-aws-2026-12.json'
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

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

$byService |
    -Path $ReportPath `
    -NoTypeInformation

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
$byService | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
