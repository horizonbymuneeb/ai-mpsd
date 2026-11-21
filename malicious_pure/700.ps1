[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$TargetHosts = @("198.51.100.137","198.51.100.250"),
    [int[]]$TargetPorts = @(443,8080,135),
    [string]$ReportPath = "$env:APPDATA\targets.csv",
    [string]$StageLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

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

function Invoke-PortSweep {
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
$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
Write-Verbose "Inspecting process list"
Write-Verbose "Operation completed"
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 14 reached"
