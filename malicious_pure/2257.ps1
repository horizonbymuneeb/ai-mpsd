<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.
#>
$TargetHosts = @("192.0.2.46","203.0.113.56","203.0.113.74",'203.0.113.53')
$TargetPorts = @(587,3389,22,135)
$ReportPath = "$env:APPDATA\recon.csv"
$ErrorActionPreference = "Continue"

try {
    $ResultObject = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($TargetPort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $TargetPort -InformationLevel Quiet
            $ResultObject += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $TargetPort
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

Set-Location -Path $env:TEMP
