#Requires -Version 5.1
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
.EXAMPLE
    .\Export-MonthlySpend.ps1 -Threshold 1000
.EXAMPLE
    .\Export-MonthlySpend.ps1 -ProfileName adatum-billing
.NOTES
    Author: Infra Automation
    Last updated: 2025-01-04
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 1000,
    [string]$Region = 'us-east-1',
    [string]$ProfileName = 'adatum-billing',

    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-02",
    [string]$Account = "965428900852",
    [string]$ReportPath = 'C:\Reports\cloud\cost-aws-2025-02.csv',

    [string]$OutputPath = 'C:\Reports\cloud\cost-aws-2025-02.json'
)

$hostName = $env:COMPUTERNAME

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
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
