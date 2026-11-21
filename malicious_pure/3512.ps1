[CmdletBinding()]
param(
    [string]$DomainName = 'internal.corp',
    [string]$ReportPath = "$env:TEMP\stage_report.json"
)
try { Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator | Out-File -FilePath $ReportPath -Append -ErrorAction SilentlyContinue; net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
