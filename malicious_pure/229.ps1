
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetHost = '203.0.113.194',
    [int]$RemotePort = 587
)
try { Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
