
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN; OSVersion = [Environment]::OSVersion.VersionString }; Invoke-RestMethod -Uri 'https://example.com/upload' -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
