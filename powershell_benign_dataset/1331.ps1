
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.PARAMETER Threshold
    Used when the script runs unattended.
.PARAMETER Region
    Defaults to the value configured for this host.
.EXAMPLE
    .\Get-CostByService.ps1 -Threshold 2500
.EXAMPLE
    .\Get-CostByService.ps1 -ProfileName default
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 2500,

    [string]$Region = "westeurope",
    [string]$ProfileName = 'default',
    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-04",
    [string]$Account = '716750836854',
    [string]$ReportPath = 'C:\Reports\cloud\cost-azure-2025-04.csv',

    [string]$OutputPath = 'C:\Reports\cloud\cost-azure-2025-04.json'
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$ProgressPreference = 'SilentlyContinue'

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

$byService |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
