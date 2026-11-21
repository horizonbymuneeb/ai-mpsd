[CmdletBinding()]
param(
    [string]$DomainName = "contoso.com",
    [string]$ReportPath = 'C:\ProgramData\stage_report.json'
)
Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator | Out-File -FilePath $ReportPath -Append
net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
