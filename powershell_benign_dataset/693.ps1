
$Servers = @('sql-prod-02', 'srv01', 'dc02')
$Services = @('DNS', 'SNMP', 'MSSQLSERVER', 'W3SVC')
$Port = 443
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2026-04-20.csv'


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
