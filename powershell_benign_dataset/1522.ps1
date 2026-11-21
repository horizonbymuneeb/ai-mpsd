
#Requires -Version 5.1
$Servers = @('app-prod-01', 'srv01', 'sql-prod-02', 'mgmt01')
$Services = @('DNS', 'MSSQLSERVER', 'WinRM')
$Port = 3389
$TimeoutMilliseconds = 5000
$ReportPath = 'C:\Reports\service-health-2024-07-24.csv'


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
