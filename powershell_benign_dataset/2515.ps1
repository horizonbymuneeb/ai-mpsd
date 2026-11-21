
$ErrorActionPreference = 'Stop'

$Threshold   = 500
$Region      = "ap-southeast-2"
$ProfileName = 'adatum-billing'
$Month       = "2026-05"
$Account     = "315794269916"
$ReportPath  = 'D:\Ops\finops\cost-aws-2026-05.csv'
$OutputPath  = 'D:\Ops\finops\cost-aws-2026-05.json'


$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {
    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
