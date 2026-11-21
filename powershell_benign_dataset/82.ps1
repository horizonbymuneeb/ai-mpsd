#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$Servers = @('web-stg-01', 'srv01', 'web-prod-03')
$Services = @('MSSQLSERVER', 'W3SVC', 'SNMP', 'DNS')
$Port = 5986
$TimeoutMilliseconds = 2000
$ReportPath = "C:\Reports\service-health-2024-04-12.csv"


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
