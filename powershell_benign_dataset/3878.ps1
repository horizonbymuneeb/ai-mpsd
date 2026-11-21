
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Paths are resolved relative to the invoking session.
.PARAMETER Region
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 750
.EXAMPLE
    .\Get-CloudCostReport.ps1 -ProfileName default
.NOTES
    Author: M. Rahman
    Last updated: 2025-02-17
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 750,
    [string]$Region = 'eu-west-1',
    [string]$ProfileName = 'default',
    [Parameter(Mandatory = $false)]
    [string]$Month = "2026-07",
    [string]$Account = '391883116082',
    [string]$ReportPath = "C:\Reports\cloud\cost-azure-2026-07.csv",

    [string]$OutputPath = "C:\Reports\cloud\cost-azure-2026-07.json"
)

Set-StrictMode -Version 2.0

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop
$groups = foreach ($line in $usage) {
    [pscustomobject]@{
        Period  = $line.UsageStart.ToString('yyyy-MM-dd')
        Service = $line.ServiceName
        Amount  = [math]::Round([double]$line.PretaxCost, 2)
        Unit    = $line.Currency
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

$byService | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
