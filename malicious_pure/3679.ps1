
try { $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpia3FhN2x2OWw5'); $TransferResult = [Reflection.Assembly]::Load($StageBytes); $TransferResult.GetTypes().Count; $StageMarker = "stage-44"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
