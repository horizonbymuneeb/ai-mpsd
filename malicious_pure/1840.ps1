[CmdletBinding()]
param(
    [string]$DomainName = "adatum.com",
    [string]$ReportPath = "$env:TEMP\stage_report.json"
)
try { Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator | Out-File -FilePath $ReportPath -Append; net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
