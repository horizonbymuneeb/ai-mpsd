[CmdletBinding()]
param(
    [string[]]$TargetHosts = @("198.51.100.111",'192.0.2.202','203.0.113.135','192.0.2.178'),
    [int[]]$TargetPorts = @(143,993,22,80),
    [string]$ReportPath = "$env:TEMP\sweep.csv"
)
$ErrorActionPreference = "Continue"

try {
    $ResultObject = @()
    foreach ($TargetAddress in $TargetHosts) {
        foreach ($ScanPort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $TargetAddress -Port $ScanPort -InformationLevel Quiet
            $ResultObject += [PSCustomObject]@{
                Host = $TargetAddress
                Port = $ScanPort
                Open = $Open
            }
        }
    }
    $ResultObject | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $ResultObject.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
