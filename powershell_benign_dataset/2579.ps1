
$ErrorActionPreference = "Stop"

$Servers = @('srv01', 'sql-prod-02', 'app-prod-01', 'web-stg-01', 'filesrv01')
$Services = @('WinRM', 'MSSQLSERVER', 'Dhcp')
$Port = 5986
$TimeoutMilliseconds = 5000
$ReportPath = "C:\Reports\service-health-2026-06-17.csv"


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
