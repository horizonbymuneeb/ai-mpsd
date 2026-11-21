
[CmdletBinding()]
param(
    [string]$TargetHost = '203.0.113.57',
    [int]$RemotePort = 139
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
