
[CmdletBinding()]
param(
    [string]$TargetHost = "192.0.2.223",
    [int]$RemotePort = 8080
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
