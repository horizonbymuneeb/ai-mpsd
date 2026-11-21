$Servers = @('filesrv01', 'mgmt01', 'sql-prod-02', 'web-prod-03')
$Services = @('DNS', 'MSSQLSERVER')
$Port = 5985
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2026-02-18.csv"


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
