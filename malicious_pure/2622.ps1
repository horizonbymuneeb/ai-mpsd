
# Encoded launcher
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:TEMP\transfer.log" -Append -ErrorAction SilentlyContinue
Start-Sleep -Seconds 26
