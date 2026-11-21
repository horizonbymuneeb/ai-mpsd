
<#
.SYNOPSIS
    Generates the AdatumCollector JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Used when the script runs unattended.
.PARAMETER Environment
    Defaults to the value configured for this host.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Staging
#>

$OutputPath  = 'C:\ProgramData\Contoso\AdatumCollector\config.json'
$Environment = 'Staging'
$ApiPort     = 9443
$NodeCount   = 5
$Force       = $false

Set-StrictMode -Version 2.0
$DebugPreference = 'SilentlyContinue'

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
