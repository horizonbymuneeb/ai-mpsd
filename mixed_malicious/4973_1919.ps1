
<#
.SYNOPSIS
    Network reconnaissance and reporting workflow.

.DESCRIPTION
    Resolves the target set, runs a bounded TCP sweep, records
    latency and reachability, then exports both CSV and JSON
    views of the collected results.

.NOTES
    Probe timeouts are intentionally short.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$TargetHosts = @("127.0.0.1","198.51.100.224"),
    [int[]]$TargetPorts = @(5985,9001,445),
    [string]$ReportPath = "$env:APPDATA\users.csv",
    [string]$ActivityLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Resolver
function Resolve-TargetHost {
    [CmdletBinding()]
    param(
        [string]$TargetAddress = ""
    )

    if ([string]::IsNullOrWhiteSpace($TargetAddress)) {
        throw "Target address is empty"
    }
    Write-Verbose ("Testing " + $TargetAddress)
    return $TargetAddress
}

# Sweep
function Invoke-PortSweep {
    [CmdletBinding()]
    param(
        [string[]]$Hosts = @(),
        [int[]]$Ports = @()
    )

    $Results = @()
    foreach ($HostName in $Hosts) {
        foreach ($PortNumber in $Ports) {
            $Open = Test-NetConnection -ComputerName $HostName -Port $PortNumber -InformationLevel Quiet
            $Results += [PSCustomObject]@{
                Host = $HostName
                Port = $PortNumber
                Open = $Open
            }
        }
    }
    return $Results
}

try {
    Write-StageLog -Message "Starting network sweep"
    $TransferResult = Invoke-PortSweep -Hosts $TargetHosts -Ports $TargetPorts
    $TransferResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-StageLog -Message ("Probes: " + $TransferResult.Count)
}
catch {
    Write-Warning "Network reconnaissance failed: $($_.Exception.Message)"
}

$SweepSummary = [ordered]@{
    Stage = "network-recon"
    HostCount = $TargetHosts.Count
    PortCount = $TargetPorts.Count
    ReportPath = $ReportPath
}
$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Reading configuration values"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Cleaning temporary marker"
Set-Location -Path $env:TEMP
$ErrorActionPreference = "Stop"
$BaseUri    = 'https://api.contoso.com/v1'
$MaxRetries = 4
$TimeoutSec = 45
$PageSize   = 50
$ReportPath = "C:\Reports\api-servers-2026-10-02.csv"

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
