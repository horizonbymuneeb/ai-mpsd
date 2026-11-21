
Invoke-WebRequest -Uri "https://example.net:443/stage2.bin" -OutFile "$env:TEMP\update.dat" -UseBasicParsing
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:TEMP\update.dat"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Verbose "stage marker 30 reached"
