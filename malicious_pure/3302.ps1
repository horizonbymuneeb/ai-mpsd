
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('198.51.100.231','203.0.113.47'),
    [int[]]$TargetPorts = @(53,21,443,22),
    [string]$ReportPath = 'C:\ProgramData\users.csv',
    [string]$TracePath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-TargetHost {
    [CmdletBinding()]
    param(
        [string]$TargetAddress = ''
    )

    if ([string]::IsNullOrWhiteSpace($TargetAddress)) {
        throw "Target address is empty"
    }
    Write-Verbose ("Testing " + $TargetAddress)
    return $TargetAddress
}

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
$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Operation completed"
Write-Verbose "Exporting operation report"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Checking local path"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
