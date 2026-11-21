
[CmdletBinding()]
param(
    [string]$TargetHost = "127.0.0.1",
    [int]$RemotePort = 5985
)
try { Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }
