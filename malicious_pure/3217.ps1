
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
    [string[]]$TargetHosts = @("192.0.2.21",'127.0.0.1',"203.0.113.109"),
    [int[]]$TargetPorts = @(135,8080),
    [string]$ReportPath = "$env:APPDATA\sweep.csv",
    [string]$ActivityLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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

try {
    Write-StageLog -Message "Starting network sweep"
    $ResultObject = Invoke-PortSweep -Hosts $TargetHosts -Ports $TargetPorts
    $ResultObject | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-StageLog -Message ("Probes: " + $ResultObject.Count)
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
Write-Verbose "Exporting operation report"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Starting workflow"
$ProgressPreference = "SilentlyContinue"
Write-Output "stage 3 initialized"
