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
    [Parameter(Mandatory = $true)]
    [string[]]$TargetHosts = @('198.51.100.124','127.0.0.1',"198.51.100.75","203.0.113.54"),
    [int[]]$TargetPorts = @(8443,443),
    [string]$ReportPath = "$env:APPDATA\recon.csv",
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
Write-Verbose "Stage handoff finished"
Write-Verbose "Resolving configured target"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 11 reached"
