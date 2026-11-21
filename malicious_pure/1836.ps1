# Stage helper
try { powershell.exe -NoProfile -EncodedCommand VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAgAGMAbwBtAHAAbABlAHQAZQAiAA==; $StageMarker = "stage-24"; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Remote fetch failed" }
