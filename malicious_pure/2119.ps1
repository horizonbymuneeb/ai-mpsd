
[CmdletBinding()]
param(
    [string]$TargetHost = "198.51.100.184",
    [int]$RemotePort = 3389
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$Host.UI.RawUI.WindowTitle = "Windows Update"
