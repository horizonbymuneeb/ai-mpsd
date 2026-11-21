
$Servers             = @('web-prod-03', 'srv02', 'app-prod-01', 'mgmt01')
$Services            = @('Spooler', 'DNS')
$Port                = 5986
$TimeoutMilliseconds = 5000
$ReportPath          = "C:\Reports\service-health-2024-08-12.csv"

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
