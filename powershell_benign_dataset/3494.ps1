
$ErrorActionPreference = "Stop"
$WarningDays = 14
$Hosts       = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com')
$Port        = 443
$ReportPath  = 'C:\Reports\cert-expiry-2025-08-12.csv'


$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
