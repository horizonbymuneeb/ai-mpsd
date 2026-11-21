<# Payload staging #>
[CmdletBinding()]
param(
    [string]$DomainName = "internal.corp",
    [string]$ReportPath = "C:\ProgramData\profile.json"
)
Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator | Out-File -FilePath $ReportPath -Append
net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append
$ProgressPreference = "SilentlyContinue"
