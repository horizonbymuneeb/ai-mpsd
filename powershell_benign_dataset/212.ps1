$ErrorActionPreference = "Stop"
$Threshold   = 1000
$Region      = 'eu-west-1'
$ProfileName = 'default'
$Month       = '2025-07'
$Account     = '369422527308'
$ReportPath  = "C:\Reports\cloud\cost-azure-2025-07.csv"
$OutputPath  = "C:\Reports\cloud\cost-azure-2025-07.json"


$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$groups = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end | ForEach-Object {
    [pscustomobject]@{ Service = $_.ServiceName; Amount = [math]::Round([double]$_.PretaxCost, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
