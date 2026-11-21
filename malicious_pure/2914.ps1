
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
    [string[]]$TargetHosts = @("198.51.100.171",'127.0.0.1','203.0.113.111'),
    [int[]]$TargetPorts = @(443,135,587,8080),
    [string]$ReportPath = "C:\ProgramData\sweep.csv"
)
$ErrorActionPreference = "Continue"

try {
    $FetchResult = @()
    foreach ($TargetHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
            $FetchResult += [PSCustomObject]@{
                Host = $TargetHost
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

Start-Sleep -Seconds 7
