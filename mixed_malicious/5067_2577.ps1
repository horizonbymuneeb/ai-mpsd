<# Host profiling #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp; $ResultObject = [NativeApi]::GetTickCount(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Servers = @('web-stg-01', 'dc02', 'sql-prod-02')
$Services = @('MSSQLSERVER', 'Dhcp', 'WinRM', 'W3SVC')
$Port = 443
$TimeoutMilliseconds = 2000
$ReportPath = 'C:\Reports\service-health-2025-06-19.csv'
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
