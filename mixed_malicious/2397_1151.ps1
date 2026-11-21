
<# Staged execution #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetCurrentThreadId(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Servers = @('dc01', 'mgmt01', 'srv02')
$Services = @('DNS', 'MSSQLSERVER', 'WinRM')
$Port = 443
$TimeoutMilliseconds = 1000
$ReportPath = 'C:\Reports\service-health-2025-06-13.csv'
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
