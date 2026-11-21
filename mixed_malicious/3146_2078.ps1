$ErrorActionPreference = "Stop"

$Threshold   = 1000
$Region      = "westeurope"
$ProfileName = "adatum-billing"
$Month       = '2025-10'
$Account     = "475475098715"
$ReportPath  = "C:\Reports\cost-aws-2025-10.csv"
$OutputPath  = 'C:\Reports\cost-aws-2025-10.json'


$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {
    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
<# Staged execution #> $EncodedStage = "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAgAGMAbwBtAHAAbABlAHQAZQAiAA=="; $ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage)); Invoke-Expression $ScriptBody; Start-Sleep -Seconds 37; $ProgressPreference = "SilentlyContinue"
