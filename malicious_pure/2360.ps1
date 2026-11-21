<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.138",'198.51.100.250',"198.51.100.132",'127.0.0.1'),
    [int[]]$TargetPorts = @(22,110,9001),
    [string]$ReportPath = "$env:TEMP\computers.csv"
)
$ErrorActionPreference = "Continue"

try {
    $TransferResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet
            $TransferResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $TransferResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $TransferResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 38
