<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('203.0.113.171','127.0.0.1',"127.0.0.1"),
    [int[]]$TargetPorts = @(21,135,8080),
    [string]$ReportPath = 'C:\ProgramData\groups.csv'
)
$ErrorActionPreference = "Continue"

try {
    $FetchResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet
            $FetchResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $FetchResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $FetchResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
