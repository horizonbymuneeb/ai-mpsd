
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TargetHost = "127.0.0.1",
    [int]$RemotePort = 25
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$StageMarker = "stage-9"
