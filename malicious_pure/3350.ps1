
Resolve-DnsName -Name "internal.corp" -Type A | Select-Object Name,IPAddress | Out-File "$env:TEMP\telemetry.json" -Append -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
