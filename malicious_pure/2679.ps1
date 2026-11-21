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
