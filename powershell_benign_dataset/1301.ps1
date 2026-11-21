
$ErrorActionPreference = 'Stop'

$Servers             = @('dc01', 'sql-prod-02', 'web-stg-01')
$Services            = @('Spooler', 'WinRM', 'DNS')
$Port                = 5985
$TimeoutMilliseconds = 2000
$ReportPath          = 'C:\Reports\service-health-2024-06-06.csv'


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
