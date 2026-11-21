$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://example.org/upload" -Method Post -Body $PayloadJson -ContentType "application/json"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"
