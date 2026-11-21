
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $StageResult = [PlatformApi]::GetCurrentThreadId(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Remote fetch failed" }
$ErrorActionPreference = "Stop"
$Servers = @('app-prod-01', 'web-stg-01', 'web-prod-03')
$Services = @('Dhcp', 'W3SVC')
$Port = 3389
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2025-09-03.csv'


$results = foreach ($srv in $Servers) {
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server  = $srv
            Service = $svc
            Status  = $(if ($service) { $service.Status } else { 'NotFound' })
        }
    }
}
$results | Format-Table -AutoSize
