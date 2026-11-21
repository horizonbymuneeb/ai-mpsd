$Servers = @('web-prod-03', 'filesrv01', 'dc02', 'srv02', 'sql-prod-02')
$Services = @('MSSQLSERVER', 'DNS')
$Port = 443
$TimeoutMilliseconds = 3000
$ReportPath = "C:\Reports\service-health-2025-10-08.csv"

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
