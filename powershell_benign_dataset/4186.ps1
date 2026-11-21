
$OutputPath = 'C:\ProgramData\Contoso\InfraRelay\config.json'
$Environment = 'Staging'
$ApiPort = 8080
$NodeCount = 6
$Force = $false
$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'InfraRelay'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
