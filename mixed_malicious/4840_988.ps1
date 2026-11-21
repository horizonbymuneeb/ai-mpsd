$Threshold = 2500
$Region = "eu-west-1"
$ProfileName = 'default'
$Month = "2025-03"
$Account = "722643952265"
$ReportPath = 'C:\Reports\cloud\cost-azure-2025-03.csv'
$OutputPath = 'C:\Reports\cloud\cost-azure-2025-03.json'


$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$groups = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end | ForEach-Object {
    [pscustomobject]@{ Service = $_.ServiceName; Amount = [math]::Round([double]$_.PretaxCost, 2) }
}

$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetTickCount(); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; $Host.UI.RawUI.WindowTitle = "Windows Update"
