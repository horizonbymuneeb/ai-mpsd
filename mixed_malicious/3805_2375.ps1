
try { $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $OperationResult = [NativeApi]::GetCurrentProcessId(); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Stage transfer failed" }
$OutputPath = 'C:\ProgramData\Contoso\AdatumCollector\config.json'
$Environment = 'Dev'
$ApiPort = 5000
$NodeCount = 5
$Force = $false

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$hostName = $env:COMPUTERNAME

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'AdatumCollector'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.adatum.com/v1'
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
    "name": "AdatumCollector",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8
