
<# Staged execution #> try { powershell.exe -NoProfile -WindowStyle Hidden -EncodedCommand VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAgAGMAbwBtAHAAbABlAHQAZQAiAA==; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
