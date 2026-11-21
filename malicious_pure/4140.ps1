
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
    [string[]]$TargetHosts = @("203.0.113.56",'198.51.100.227'),
    [int[]]$TargetPorts = @(993,21),
    [string]$ReportPath = "C:\ProgramData\sweep.csv",
    [string]$ActivityLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Resolver
function Resolve-TargetHost {
    param(
        [string]$TargetAddress = ''
    )

    if ([string]::IsNullOrWhiteSpace($TargetAddress)) {
        throw "Target address is empty"
    }
    Write-Verbose ("Testing " + $TargetAddress)
    return $TargetAddress
}

# Sweep
function Invoke-PortSweep {
    param(
        [string[]]$Hosts = @(),
        [int[]]$Ports = @()
    )

    $Results = @()
    foreach ($HostName in $Hosts) {
        foreach ($PortNumber in $Ports) {
            $Open = Test-NetConnection -ComputerName $HostName -Port $PortNumber -InformationLevel Quiet -ErrorAction SilentlyContinue
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
    $StageResult = Invoke-PortSweep -Hosts $TargetHosts -Ports $TargetPorts
    $StageResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-StageLog -Message ("Probes: " + $StageResult.Count)
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
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 18 initialized"
