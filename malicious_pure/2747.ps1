
<# Payload staging #> try { powershell.exe -NoProfile -EncodedCommand VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA==; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $StageMarker = "stage-24" } catch { Write-Warning "Remote fetch failed" }
