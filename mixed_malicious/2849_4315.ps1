<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.133","127.0.0.1",'203.0.113.3',"203.0.113.120"),
    [int[]]$TargetPorts = @(25,8080,445),
    [string]$ReportPath = "$env:APPDATA\sweep.csv"
)
$ErrorActionPreference = "Continue"

$StageResult = @()
foreach ($RemoteHost in $TargetHosts) {
    foreach ($TargetPort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $RemoteHost -Port $TargetPort -InformationLevel Quiet -ErrorAction SilentlyContinue
        $StageResult += [PSCustomObject]@{
            Host = $RemoteHost
            Port = $TargetPort
            Open = $Open
        }
    }
}
$StageResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $StageResult.Count + " probes")

Set-Location -Path $env:TEMP
#Requires -Version 5.1
$InputCsv   = "C:\Data\exports\headcount.csv"
$OutputPath = "C:\Reports\headcount-summary-2025-08-23.csv"
$GroupBy    = "Department"
$MinAmount  = 1000


if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','

$byGroup = $rows | Group-Object -Property Department | ForEach-Object {
    [pscustomobject]@{
        Department       = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}

$byGroup | Sort-Object -Property Total -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Rows: {0} | Groups: {1}" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan
