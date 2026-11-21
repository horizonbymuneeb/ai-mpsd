
<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('192.0.2.15',"198.51.100.226","192.0.2.166"),
    [int[]]$TargetPorts = @(135,443,25,5985),
    [string]$ReportPath = "$env:APPDATA\computers.csv"
)
$ErrorActionPreference = "Continue"

try {
    $ResultObject = @()
    foreach ($ComputerName in $TargetHosts) {
        foreach ($ProbePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $ComputerName -Port $ProbePort -InformationLevel Quiet -ErrorAction SilentlyContinue
            $ResultObject += [PSCustomObject]@{
                Host = $ComputerName
                Port = $ProbePort
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

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$StageMarker = "stage-41"
Start-Sleep -Seconds 43
