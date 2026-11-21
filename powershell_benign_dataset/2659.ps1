$Servers             = @('sql-prod-02', 'srv02', 'dc01', 'mgmt01')
$Services            = @('Spooler', 'WinRM', 'DNS')
$Port                = 5985
$TimeoutMilliseconds = 3000
$ReportPath          = 'C:\Reports\service-health-2026-02-02.csv'


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
