
[CmdletBinding()]
param(
    [string]$DomainName = "contoso.com",
    [string]$ReportPath = "C:\ProgramData\recon.json"
)
Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator | Out-File -FilePath $ReportPath -Append
net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
