
$ErrorActionPreference = "Stop"
$Servers = @('sql-prod-02', 'mgmt01', 'app-prod-01', 'srv02')
$Services = @('WinRM', 'Dhcp', 'Spooler')
$Port = 443
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2026-04-21.csv"

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
