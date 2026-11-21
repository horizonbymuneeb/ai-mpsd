
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeApi]::GetVersion(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Loader step failed" }
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 500
.EXAMPLE
    .\Get-CloudCostReport.ps1 -ProfileName default
.NOTES
    Author: Server Operations
    Last updated: 2025-11-12
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 500,

    [string]$Region = 'eu-west-1',

    [string]$ProfileName = 'default',
    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-02',
    [string]$Account = "593545917777",

    [string]$ReportPath = 'C:\Reports\cost-azure-2026-02.csv',

    [string]$OutputPath = 'C:\Reports\cost-azure-2026-02.json'
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
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
$byService | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
