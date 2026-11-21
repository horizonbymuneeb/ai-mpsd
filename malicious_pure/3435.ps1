[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("203.0.113.79","198.51.100.216","203.0.113.220"),
    [int[]]$TargetPorts = @(8080,25,53,8443),
    [string]$ReportPath = "C:\ProgramData\users.csv"
)
$ErrorActionPreference = "Continue"

$FetchResult = @()
foreach ($RemoteHost in $TargetHosts) {
    foreach ($TargetPort in $TargetPorts) {
        $Open = Test-NetConnection -ComputerName $RemoteHost -Port $TargetPort -InformationLevel Quiet
        $FetchResult += [PSCustomObject]@{
            Host = $RemoteHost
            Port = $TargetPort
            Open = $Open
        }
    }
}
$FetchResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Verbose ("Sweep complete: " + $FetchResult.Count + " probes")

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
