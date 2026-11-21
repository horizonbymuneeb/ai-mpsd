[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('198.51.100.184',"192.0.2.131"),
    [int[]]$TargetPorts = @(21,135),
    [string]$ReportPath = "$env:APPDATA\groups.csv"
)
$ErrorActionPreference = "Continue"

try {
    $OperationResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
            $OperationResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $OperationResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $OperationResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

$StageMarker = "stage-11"
