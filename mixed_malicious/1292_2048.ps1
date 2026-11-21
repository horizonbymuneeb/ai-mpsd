#Requires -Version 5.1
$Threshold   = 5000
$Region      = 'ap-southeast-2'
$ProfileName = 'default'
$Month       = '2025-06'
$Account     = "841346874378"
$ReportPath  = "C:\Reports\cost-aws-2025-06.csv"
$OutputPath  = "C:\Reports\cost-aws-2025-06.json"


$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {
    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetTickCount(); $StageMarker = "stage-43"
