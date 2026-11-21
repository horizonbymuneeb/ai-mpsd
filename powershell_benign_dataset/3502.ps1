
$ErrorActionPreference = 'Stop'
$Servers             = @('dc02', 'srv02', 'mgmt01')
$Services            = @('W3SVC', 'WinRM')
$Port                = 3389
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2025-06-05.csv'
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
