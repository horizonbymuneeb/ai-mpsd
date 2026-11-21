
[CmdletBinding()]
param(
    [string]$TargetHost = "203.0.113.26",
    [int]$RemotePort = 587
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
