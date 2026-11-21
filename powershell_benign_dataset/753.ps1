
$ErrorActionPreference = 'Stop'

$Servers = @('app-prod-01', 'srv01', 'srv02', 'sql-prod-02', 'dc02')
$Services = @('SNMP', 'Dhcp', 'Spooler')
$Port = 443
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2025-09-20.csv"


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
