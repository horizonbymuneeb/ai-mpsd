
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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$TargetHosts = @("203.0.113.42","192.0.2.10"),
    [int[]]$TargetPorts = @(3389,445),
    [string]$ReportPath = "C:\ProgramData\users.csv",
    [string]$TracePath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Resolving configured target"
Write-Verbose "Exporting operation report"
Write-Verbose "Checking local path"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
