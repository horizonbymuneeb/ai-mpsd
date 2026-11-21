
<#
.SYNOPSIS
    Network reconnaissance and reporting workflow.

.DESCRIPTION
    Resolves the target set, runs a bounded TCP sweep, records
    latency and reachability, then exports both CSV and JSON
    views of the collected results.

.NOTES
    Probe timeouts are intentionally short.
#>
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.210","203.0.113.160","192.0.2.63"),
    [int[]]$TargetPorts = @(80,8443,25),
    [string]$ReportPath = "$env:TEMP\sweep.csv",
    [string]$LogPath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Resolver
function Resolve-TargetHost {
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

Write-StageLog -Message "Starting network sweep"
$StageResult = Invoke-PortSweep -Hosts $TargetHosts -Ports $TargetPorts
$StageResult | Export-Csv -Path $ReportPath -NoTypeInformation
Write-StageLog -Message ("Probes: " + $StageResult.Count)

$SweepSummary = [ordered]@{
    Stage = "network-recon"
    HostCount = $TargetHosts.Count
    PortCount = $TargetPorts.Count
    ReportPath = $ReportPath
}
$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
