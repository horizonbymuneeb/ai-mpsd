
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("203.0.113.244",'203.0.113.218'),
    [int[]]$TargetPorts = @(135,21,80),
    [string]$ReportPath = "C:\ProgramData\computers.csv"
)
$ErrorActionPreference = "Continue"

$FetchResult = @()
foreach ($TargetAddress in $TargetHosts) {
    foreach ($TargetPort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $TargetAddress -Port $TargetPort -InformationLevel Quiet
        $FetchResult += [PSCustomObject]@{
            Host = $TargetAddress
            Port = $TargetPort
            Open = $Open
        }
    }
}
$FetchResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $FetchResult.Count + " probes")

$Host.UI.RawUI.WindowTitle = "Windows Update"
