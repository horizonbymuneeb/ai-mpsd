
# Stage helper
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:APPDATA\report.txt" -Append -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
