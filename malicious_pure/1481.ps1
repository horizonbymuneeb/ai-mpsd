
$TargetHosts = @('192.0.2.195','192.0.2.61','198.51.100.238')
$TargetPorts = @(80,8443,25,3389)
$ReportPath = "C:\ProgramData\sweep.csv"
$ErrorActionPreference = "Continue"

try {
    $ResultObject = @()
    foreach ($TargetAddress in $TargetHosts) {
        foreach ($ProbePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $TargetAddress -Port $ProbePort -InformationLevel Quiet
            $ResultObject += [PSCustomObject]@{
                Host = $TargetAddress
                Port = $ProbePort
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
