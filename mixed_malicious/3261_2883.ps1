
[CmdletBinding()]
param(
    [int]$TimeoutSec = 50
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $StageResult)
$AmsiMarker = "amsiInitFailed"

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-32"
$ErrorActionPreference = "Stop"
$BaseUri = "https://api.contoso.com/v1"
$MaxRetries = 3
$TimeoutSec = 15
$PageSize = 25
$ReportPath = "C:\Reports\api-servers-2024-08-09.csv"


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
