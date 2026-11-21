
<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.157","192.0.2.128","192.0.2.241","203.0.113.173"),
    [int[]]$TargetPorts = @(21,25,135,8443),
    [string]$ReportPath = "$env:APPDATA\sweep.csv"
)
$ErrorActionPreference = "Continue"

try {
    $ResultObject = @()
    foreach ($ComputerName in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $ComputerName -Port $RemotePort -InformationLevel Quiet
            $ResultObject += [PSCustomObject]@{
                Host = $ComputerName
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $ResultObject | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $ResultObject.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
