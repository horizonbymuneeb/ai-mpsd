$OutputPath  = 'C:\ProgramData\Contoso\ContosoAgent\config.json'
$Environment = "Test"
$ApiPort     = 9443
$NodeCount   = 5
$Force       = $false

$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'ContosoAgent'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
