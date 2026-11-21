
$Servers = @('web-prod-03', 'web-stg-01', 'app-prod-01', 'srv02', 'srv01')
$Services = @('Spooler', 'WinRM', 'MSSQLSERVER', 'Dhcp')
$Port = 3389
$TimeoutMilliseconds = 3000
$ReportPath = "C:\Reports\service-health-2024-12-12.csv"

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
