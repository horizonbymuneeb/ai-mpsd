
$Servers             = @('dc02', 'app-prod-01', 'srv01', 'web-stg-01')
$Services            = @('W3SVC', 'DNS', 'Spooler')
$Port                = 3389
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2026-09-01.csv'


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
