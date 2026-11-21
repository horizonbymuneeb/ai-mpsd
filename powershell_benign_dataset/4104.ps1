$ErrorActionPreference = "Stop"
$Threshold   = 750
$Region      = "westeurope"
$ProfileName = "contoso-prod"
$Month       = '2026-12'
$Account     = '481179212628'
$ReportPath  = 'D:\Ops\finops\cost-azure-2026-12.csv'
$OutputPath  = "D:\Ops\finops\cost-azure-2026-12.json"
$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$groups = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end | ForEach-Object {
    [pscustomobject]@{ Service = $_.ServiceName; Amount = [math]::Round([double]$_.PretaxCost, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
