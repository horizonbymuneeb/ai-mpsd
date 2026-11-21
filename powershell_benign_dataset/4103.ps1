#Requires -Version 5.1
$WarningDays = 60
$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com')
$Port = 8443
$ReportPath = 'C:\Reports\cert-expiry-2024-10-26.csv'


$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
