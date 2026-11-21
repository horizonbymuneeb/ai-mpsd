
$OutputPath = 'C:\ProgramData\Contoso\AdatumCollector\config.json'
$Environment = 'Staging'
$ApiPort = 8443
$NodeCount = 5
$Force = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'AdatumCollector'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
