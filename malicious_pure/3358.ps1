
[CmdletBinding()]
param(
    [string]$TargetHost = '198.51.100.81',
    [int]$RemotePort = 139
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$Host.UI.RawUI.WindowTitle = "Windows Update"
