<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TargetHost = '203.0.113.63',
    [int]$RemotePort = 143
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$StageMarker = "stage-37"
