
[CmdletBinding()]
param(
    [string]$TargetHost = "192.0.2.240",
    [int]$RemotePort = 80
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$ProgressPreference = "SilentlyContinue"
