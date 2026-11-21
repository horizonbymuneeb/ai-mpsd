
#Requires -Version 5.1
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Paths are resolved relative to the invoking session.
.PARAMETER Region
    Used when the script runs unattended.
.EXAMPLE
    .\Get-CloudCostReport.ps1 -Threshold 500
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 500,

    [string]$Region = 'eu-west-1',

    [string]$ProfileName = 'default',
    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-05',

    [string]$Account = '302978377325',

    [string]$ReportPath = "D:\Ops\finops\cost-aws-2026-05.csv",

    [string]$OutputPath = 'D:\Ops\finops\cost-aws-2026-05.json'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$hostName = $env:COMPUTERNAME
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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath

$jsonBody = $byService | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8

$overThreshold = $byService | Where-Object { $_.Amount -ge ($Threshold / 10) }
$overThreshold | Export-Csv -Path $ReportPath.Replace('.csv', '-top.csv') -NoTypeInformation -Encoding UTF8

$daily = $groups | Group-Object -Property Period | ForEach-Object {
    [pscustomobject]@{
        Period = $_.Name
        Amount = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Period

$style = @'
<style>
body { font-family: Calibri; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$daily | ConvertTo-Html -Title 'Daily cloud spend' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$summaryBody = @"
Provider  : aws
Account   : $Account
Period    : $Month
Total     : $total
Threshold : $Threshold
"@

$MailTo = "finops@contoso.com"

Send-MailMessage -To $MailTo -From "finops@contoso.com" -Subject 'Monthly cloud cost report' `
    -Body $summaryBody -SmtpServer 'smtp.contoso.com' -Port 25 -UseSsl

if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
Write-Host ("Report written to {0}" -f $ReportPath) -ForegroundColor Green

$budgetFile = Join-Path $PSScriptRoot 'budget.json'
if (Test-Path -LiteralPath $budgetFile) {
    $budget = Get-Content -LiteralPath $budgetFile -Raw | ConvertFrom-Json
    Write-Verbose ("Budget file loaded: {0}" -f $budgetFile)
}

$cheapest = $byService | Sort-Object -Property Amount | Select-Object -First 5
$cheapest | Format-Table -AutoSize

$history = Join-Path (Split-Path -Parent $ReportPath) 'cost-history.csv'
Write-Verbose ("History file: {0}" -f $history)

$serviceCount = @($byService).Count
Write-Verbose ("Services with spend: {0}" -f $serviceCount)
Write-Verbose ("Provider profile: {0}" -f $ProfileName)

$average = [math]::Round(($total / [math]::Max(@($byService).Count, 1)), 2)
Write-Verbose ("Average cost per service: {0:N2}" -f $average)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)
