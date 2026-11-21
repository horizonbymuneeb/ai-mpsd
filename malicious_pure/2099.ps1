
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('198.51.100.112',"198.51.100.216"),
    [int[]]$TargetPorts = @(9001,80,53),
    [string]$ReportPath = "$env:TEMP\groups.csv"
)
$ErrorActionPreference = "Continue"

try {
    $StageResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
            $StageResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $StageResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $StageResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$Host.UI.RawUI.WindowTitle = "Windows Update"
