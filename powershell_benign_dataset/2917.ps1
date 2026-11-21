$Servers             = @('srv01', 'mgmt01', 'srv02', 'web-stg-01', 'sql-prod-02')
$Services            = @('SNMP', 'DNS')
$Port                = 443
$TimeoutMilliseconds = 5000
$ReportPath          = 'C:\Reports\service-health-2024-08-06.csv'


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
