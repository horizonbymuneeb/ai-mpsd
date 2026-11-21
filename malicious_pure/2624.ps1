[CmdletBinding()]
param(
    [string]$TargetHost = "127.0.0.1",
    [int]$RemotePort = 5985
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
Set-Location -Path $env:TEMP
