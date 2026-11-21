
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
    [string[]]$TargetHosts = @('192.0.2.66','127.0.0.1',"203.0.113.95"),
    [int[]]$TargetPorts = @(587,443,9001),
    [string]$ReportPath = "C:\ProgramData\groups.csv"
)
$ErrorActionPreference = "Continue"

$StageResult = @()
foreach ($ComputerName in $TargetHosts) {
    foreach ($TargetPort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $ComputerName -Port $TargetPort -InformationLevel Quiet
        $StageResult += [PSCustomObject]@{
            Host = $ComputerName
            Port = $TargetPort
            Open = $Open
        }
    }
}
$StageResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $StageResult.Count + " probes")

$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 21 initialized"
Set-Location -Path $env:TEMP
