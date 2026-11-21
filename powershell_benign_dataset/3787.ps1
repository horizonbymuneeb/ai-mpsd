
$ErrorActionPreference = "Stop"
$Servers = @('app-prod-01', 'web-stg-01', 'web-prod-03')
$Services = @('Dhcp', 'W3SVC')
$Port = 3389
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2025-09-03.csv'


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
