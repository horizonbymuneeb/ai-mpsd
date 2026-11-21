$ErrorActionPreference = "Stop"

$Servers = @('sql-prod-02', 'srv01', 'dc01', 'filesrv01', 'web-stg-01')
$Services = @('Dhcp', 'W3SVC', 'MSSQLSERVER')
$Port = 5986
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2024-03-19.csv"


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
