$ErrorActionPreference = "Stop"

$BaseUri = "https://api.contoso.com/v1"
$MaxRetries = 2
$TimeoutSec = 45
$PageSize = 50
$ReportPath = 'C:\Reports\api-servers-2024-02-11.csv'


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
