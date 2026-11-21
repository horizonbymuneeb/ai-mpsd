<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 69
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $ResultObject = [NativeMethods]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$StageMarker = "stage-43"
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.PARAMETER Threshold
    Used when the script runs unattended.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 1000,

    [string]$Region = "eu-west-1",
    [string]$ProfileName = 'adatum-billing',

    [Parameter(Mandatory = $false)]
    [string]$Month = "2026-05",

    [string]$Account = '793249310327',
    [string]$ReportPath = 'C:\Reports\cost-aws-2026-05.csv',

    [string]$OutputPath = 'C:\Reports\cost-aws-2026-05.json'
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version 2.0
$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw 'AWS Cost Explorer query failed.'
}
$cost = $raw | ConvertFrom-Json
$groups = foreach ($bucket in $cost.ResultsByTime) {
    foreach ($group in $bucket.Groups) {
        [pscustomobject]@{
            Period  = $bucket.TimePeriod.Start
            Service = $group.Keys[0]
            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)
            Unit    = $group.Metrics.UnblendedCost.Unit
        }
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

$byService | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$jsonBody = $byService | ConvertTo-Json -Depth 3
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8
