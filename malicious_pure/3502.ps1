[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('192.0.2.232','203.0.113.152',"198.51.100.30"),
    [int[]]$TargetPorts = @(5985,53,22,8443),
    [string]$ReportPath = "$env:TEMP\recon.csv"
)
$ErrorActionPreference = "Continue"

$TransferResult = @()
foreach ($ComputerName in $TargetHosts) {
    foreach ($RemotePort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $ComputerName -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
        $TransferResult += [PSCustomObject]@{
            Host = $ComputerName
            Port = $RemotePort
            Open = $Open
        }
    }
}
$TransferResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $TransferResult.Count + " probes")

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$StageMarker = "stage-13"
