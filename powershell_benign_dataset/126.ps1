$Servers             = @('dc02', 'srv01', 'filesrv01')
$Services            = @('MSSQLSERVER', 'Dhcp', 'WinRM', 'Spooler')
$Port                = 3389
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2026-06-04.csv'

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
