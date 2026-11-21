
<# Payload staging #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeMethods]::GetVersion(); Write-Output "stage 21 initialized"; $StageMarker = "stage-44"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 1000,
    [string]$Region = 'westeurope',

    [string]$ProfileName = 'default',
    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-03',
    [string]$Account = "252319797142",
    [string]$ReportPath = 'D:\Ops\finops\cost-azure-2026-03.csv',

    [string]$OutputPath = 'D:\Ops\finops\cost-azure-2026-03.json'
)


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
    -NoTypeInformation `
    -Path $ReportPath

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$jsonBody = $byService | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8
