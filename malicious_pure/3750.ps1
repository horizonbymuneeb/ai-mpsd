<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("192.0.2.185","192.0.2.163",'192.0.2.5','198.51.100.196'),
    [int[]]$TargetPorts = @(8443,25,21,445),
    [string]$ReportPath = "$env:APPDATA\groups.csv"
)
$ErrorActionPreference = "Continue"

$FetchResult = @()
foreach ($RemoteHost in $TargetHosts) {
    foreach ($TargetPort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $RemoteHost -Port $TargetPort -InformationLevel Quiet
        $FetchResult += [PSCustomObject]@{
            Host = $RemoteHost
            Port = $TargetPort
            Open = $Open
        }
    }
}
$FetchResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $FetchResult.Count + " probes")

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
