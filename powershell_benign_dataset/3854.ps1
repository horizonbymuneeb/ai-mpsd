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
    Defaults to the value configured for this host.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 2500
.NOTES
    Author: Infra Automation
    Last updated: 2026-04-06
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 2500,

    [string]$Region = "eu-west-1",
    [string]$ProfileName = "adatum-billing",

    [Parameter(Mandatory = $false)]
    [string]$Month = '2025-07',

    [string]$Account = "169406785678",
    [string]$ReportPath = "C:\Reports\cost-aws-2025-07.csv",
    [string]$OutputPath = "C:\Reports\cost-aws-2025-07.json"
)

$ErrorActionPreference = "Stop"
$hostName = $env:COMPUTERNAME
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
