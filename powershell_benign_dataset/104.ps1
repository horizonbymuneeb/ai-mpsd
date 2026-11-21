$Servers = @('sql-prod-02', 'srv02', 'dc02', 'web-stg-01')
$Services = @('MSSQLSERVER', 'W3SVC', 'SNMP', 'DNS')
$Port = 5985
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2025-11-10.csv'


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
