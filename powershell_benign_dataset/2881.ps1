$ErrorActionPreference = 'Stop'
$Servers = @('dc01', 'web-stg-01', 'app-prod-01')
$Services = @('WinRM', 'W3SVC')
$Port = 5985
$TimeoutMilliseconds = 2000
$ReportPath = 'C:\Reports\service-health-2026-11-07.csv'


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
