#Requires -Version 5.1
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.NOTES
    Author: Server Operations
    Last updated: 2025-02-24
#>

$Threshold   = 500
$Region      = "eu-west-1"
$ProfileName = 'default'
$Month       = '2025-11'
$Account     = "408847194474"
$ReportPath  = "C:\Reports\cloud\cost-azure-2025-11.csv"
$OutputPath  = 'C:\Reports\cloud\cost-azure-2025-11.json'

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$InformationPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath
$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
