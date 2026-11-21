$Servers             = @('dc01', 'srv01', 'web-stg-01')
$Services            = @('DNS', 'Dhcp')
$Port                = 5985
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2025-06-24.csv'

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
