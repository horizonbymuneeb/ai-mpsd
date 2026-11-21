
<#
.SYNOPSIS
    TCP reachability sweep.

.DESCRIPTION
    Probes a bounded list of hosts and ports, captures one
    result object per probe and exports the sweep as CSV.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.138",'198.51.100.250',"198.51.100.132",'127.0.0.1'),
    [int[]]$TargetPorts = @(22,110,9001),
    [string]$ReportPath = "$env:TEMP\computers.csv"
)
$ErrorActionPreference = "Continue"

try {
    $TransferResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet
            $TransferResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $TransferResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $TransferResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 38
$BaseUri    = 'https://api.adatum.com/v1'
$MaxRetries = 2
$TimeoutSec = 15
$PageSize   = 50
$ReportPath = "C:\Reports\api-servers-2024-04-01.csv"


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
