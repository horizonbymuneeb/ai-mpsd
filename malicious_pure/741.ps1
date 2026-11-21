
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TargetHost = '192.0.2.23',
    [int]$RemotePort = 443
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
Start-Sleep -Seconds 43
