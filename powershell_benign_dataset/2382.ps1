
$Servers             = @('sql-prod-02', 'srv01', 'srv02')
$Services            = @('SNMP', 'Spooler', 'MSSQLSERVER', 'Dhcp')
$Port                = 5986
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2024-12-10.csv'

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
