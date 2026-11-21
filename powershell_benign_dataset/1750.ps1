
$Servers             = @('filesrv01', 'dc02', 'srv02', 'srv01')
$Services            = @('Dhcp', 'SNMP', 'WinRM')
$Port                = 3389
$TimeoutMilliseconds = 2000
$ReportPath          = "C:\Reports\service-health-2024-05-16.csv"


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
