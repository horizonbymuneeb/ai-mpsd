
# Remote staging
try { rundll32.exe shell32.dll,ShellExec_RunDLL "calc.exe"; Set-Location -Path $env:TEMP; $StageMarker = "stage-2" } catch { Write-Warning "Stage transfer failed" }
