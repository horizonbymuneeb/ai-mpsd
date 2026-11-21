
whoami /groups /fo csv | Out-File "$env:APPDATA\stage.log" -Append -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
