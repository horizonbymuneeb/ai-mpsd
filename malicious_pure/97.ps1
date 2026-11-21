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
    [string[]]$TargetHosts = @("203.0.113.246","203.0.113.60"),
    [int[]]$TargetPorts = @(80,143,22),
    [string]$ReportPath = "C:\ProgramData\computers.csv"
)
$ErrorActionPreference = "Continue"

$ResultObject = @()
foreach ($TargetHost in $TargetHosts) {
    foreach ($RemotePort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
        $ResultObject += [PSCustomObject]@{
            Host = $TargetHost
            Port = $RemotePort
            Open = $Open
        }
    }
}
$ResultObject | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $ResultObject.Count + " probes")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
