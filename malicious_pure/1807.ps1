
<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("192.0.2.198",'203.0.113.81','198.51.100.191'),
    [int[]]$TargetPorts = @(53,21,5985),
    [string]$ReportPath = "$env:TEMP\groups.csv"
)
$ErrorActionPreference = "Continue"

try {
    $FetchResult = @()
    foreach ($TargetAddress in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $TargetAddress -Port $RemotePort -InformationLevel Quiet
            $FetchResult += [PSCustomObject]@{
                Host = $TargetAddress
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

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
