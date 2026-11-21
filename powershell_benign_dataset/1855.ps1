$ErrorActionPreference = 'Stop'
$OutputPath = "C:\ProgramData\Contoso\AdatumCollector\config.json"
$Environment = 'Test'
$ApiPort = 5000
$NodeCount = 6
$Force = $false

$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'AdatumCollector'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
